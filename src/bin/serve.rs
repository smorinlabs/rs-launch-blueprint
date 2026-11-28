//! Optional web service binary entrypoint (`rslbp-serve`, requires `web` feature; `R69`, `R77`,
//! `R80`, `R67`).

#![deny(clippy::print_stdout, clippy::print_stderr)]

use std::env;
use std::io::{self, Write as _};
use std::path::PathBuf;
use std::process::ExitCode;
use std::sync::Arc;

use clap::Parser;
use clap::error::ErrorKind;
#[cfg(not(feature = "otel"))]
use rs_launch_blueprint::init_telemetry;
use rs_launch_blueprint::{
    ConfigDiscoveryInputs, DEFAULT_API_BASE_URL, DiagnosticsContext, ErrorCode, ErrorEnvelope,
    Exit, LogLevel, Paths, Profile, TOKEN_ENV_VAR, TokenResolutionInputs, VERSION,
    build_web_app_state, default_credential_store, in_memory_service, load_config,
    production_service, resolve_token, run_diagnostics,
};
use rs_launch_blueprint_web::{
    DiagnosticsRunner, WebSettings, install_panic_hook, run_server_blocking,
};

/// Minimal R4.1 core CLI surface for `rslbp-serve`; all service configuration lives in
/// `RSLBP_WEB_*` environment variables (`R77`).
#[derive(Debug, Parser)]
#[command(
    name = "rslbp-serve",
    version = VERSION,
    about = "Run the optional rs-launch-blueprint HTTP API service",
    long_about = "Run the optional rs-launch-blueprint HTTP API service.\n\nService configuration is supplied via RSLBP_WEB_* environment variables; stdout remains empty during serving while structured logs go to stderr."
)]
struct ServeArgs {
    /// Increase diagnostic log verbosity (-v = info, -vv = debug, -vvv = trace).
    #[arg(short = 'v', long = "verbose", action = clap::ArgAction::Count)]
    verbose: u8,

    /// Suppress non-error diagnostic logs.
    #[arg(short = 'q', long = "quiet", action = clap::ArgAction::SetTrue)]
    quiet: bool,

    /// Explicit path to a configuration file.
    #[arg(long = "config", value_name = "PATH")]
    config: Option<PathBuf>,

    /// Enable trace-level debug diagnostics.
    #[arg(long = "debug", action = clap::ArgAction::SetTrue)]
    debug: bool,
}

fn write_stdout(text: &str) {
    let mut out = io::stdout().lock();
    let _ = out.write_all(text.as_bytes());
    let _ = out.flush();
}

fn write_stderr_error(code: ErrorCode, message: &str, hint: Option<&str>) {
    let env = ErrorEnvelope::new(code, message, hint.map(str::to_owned));
    let mut err = io::stderr().lock();
    if let Ok(json) = serde_json::to_string(&env) {
        let _ = writeln!(err, "{json}");
    } else {
        let _ = writeln!(err, "error [{code}]: {message}");
    }
    let _ = err.flush();
}

fn effective_log_level(args: &ServeArgs, settings: &WebSettings) -> LogLevel {
    if args.debug {
        return LogLevel::Trace;
    }
    if args.quiet {
        return LogLevel::Error;
    }
    match args.verbose {
        0 => settings.log_level,
        1 => LogLevel::Info,
        2 => LogLevel::Debug,
        _ => LogLevel::Trace,
    }
}

fn main() -> ExitCode {
    let args = match ServeArgs::try_parse() {
        Ok(parsed) => parsed,
        Err(err) => match err.kind() {
            ErrorKind::DisplayHelp => {
                write_stdout(&err.to_string());
                return Exit::Success.into();
            }
            ErrorKind::DisplayVersion => {
                write_stdout(&format!("rslbp-serve {VERSION}\n"));
                return Exit::Success.into();
            }
            _ => {
                write_stderr_error(
                    ErrorCode::Usage,
                    err.to_string().trim(),
                    Some("run `rslbp-serve --help` for supported flags"),
                );
                return Exit::Usage.into();
            }
        },
    };

    // 1. Parse and validate all RSLBP_WEB_* settings once at startup before telemetry or bind (R77).
    let settings = match WebSettings::from_env() {
        Ok(s) => s,
        Err(err) => {
            write_stderr_error(
                err.error_code(),
                &err.to_string(),
                Some("check RSLBP_WEB_* environment variables"),
            );
            return Exit::Usage.into();
        }
    };

    // 2. Initialize service telemetry on stderr (never stdout), optional OTel bridge, and process
    //    panic hook (R58, R75, R78).
    let level = effective_log_level(&args, &settings);
    let profile = Profile::Service {
        level,
        format: settings.log_format,
    };

    #[cfg(feature = "otel")]
    let otel_guard = {
        let otel_cfg = rs_launch_blueprint::OtelConfig::from_process_env(
            settings.otel_enabled,
            settings.drain_budget(),
        );
        match rs_launch_blueprint::init_otel_from_config(&otel_cfg) {
            rs_launch_blueprint::OtelInit::Active { layer, guard } => {
                let _telemetry =
                    rs_launch_blueprint::init_telemetry_with_otel(profile, Some(layer));
                Some(guard)
            }
            rs_launch_blueprint::OtelInit::Disabled => {
                let _telemetry = rs_launch_blueprint::init_telemetry_with_otel(profile, None);
                None
            }
            rs_launch_blueprint::OtelInit::Unavailable { reason } => {
                let _telemetry = rs_launch_blueprint::init_telemetry_with_otel(profile, None);
                tracing::warn!(error = %reason, "otel_unavailable");
                None
            }
        }
    };

    #[cfg(not(feature = "otel"))]
    {
        let _telemetry = init_telemetry(profile);
        let otlp_endpoint = env::var("OTEL_EXPORTER_OTLP_ENDPOINT")
            .ok()
            .or_else(|| env::var("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT").ok());
        rs_launch_blueprint::warn_if_otlp_env_ignored(
            settings.otel_enabled,
            otlp_endpoint.as_deref(),
        );
    }

    install_panic_hook();

    // 3. Resolve XDG paths and load layered config (honoring --config / RSLBP_CONFIG).
    let cwd = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let paths = Paths::from_process_env().unwrap_or_else(|_| {
        Paths::from_roots(
            cwd.join(".config"),
            cwd.join(".local/share"),
            cwd.join(".local/state"),
            cwd.join(".cache"),
        )
    });
    let explicit_env_cfg = env::var_os("RSLBP_CONFIG");
    let xdg_config_dirs = env::var_os("XDG_CONFIG_DIRS");
    if let Err(err) = load_config(&ConfigDiscoveryInputs {
        explicit_flag: args.config.as_deref(),
        explicit_env: explicit_env_cfg.as_deref(),
        cwd: &cwd,
        paths: &paths,
        xdg_config_dirs: xdg_config_dirs.as_deref(),
    }) {
        write_stderr_error(err.error_code(), &err.to_string(), err.hint().as_deref());
        return err.error_code().exit().into();
    }

    let active_config_path = args
        .config
        .clone()
        .or_else(|| {
            explicit_env_cfg
                .as_deref()
                .filter(|v| !v.is_empty())
                .map(PathBuf::from)
        })
        .unwrap_or_else(|| paths.config_file());

    // 4. Resolve optional API credentials; fall back to in-memory service when no token is configured.
    let cred_store = default_credential_store(&paths);
    let env_token = env::var(TOKEN_ENV_VAR).ok();
    let token_res = resolve_token(&TokenResolutionInputs {
        token_file: None,
        stdin_token: None,
        env_token: env_token.as_deref(),
        store: Some(&cred_store),
    });

    let (service, token_source, token_error) = match token_res {
        Ok(resolution) => match resolution.resolved {
            Some(resolved) => {
                let src = resolved.source.as_str().to_owned();
                let api_url = env::var("RSLBP_API_URL")
                    .ok()
                    .filter(|v| !v.trim().is_empty())
                    .unwrap_or_else(|| DEFAULT_API_BASE_URL.to_owned());
                (production_service(api_url, resolved.token), Some(src), None)
            }
            None => (in_memory_service([]), None, None),
        },
        Err(err) => (in_memory_service([]), None, Some(err.to_string())),
    };

    let diag_cfg_path = active_config_path;
    let diagnostics: DiagnosticsRunner = Arc::new(move || {
        run_diagnostics(&DiagnosticsContext {
            config_path: &diag_cfg_path,
            token_source: token_source.as_deref(),
            token_error: token_error.as_deref(),
        })
    });

    let state = build_web_app_state(service, settings, diagnostics);

    // 5. Run the multi-threaded Tokio server inside crates/web until SIGINT/SIGTERM, then flush
    //    buffered OTel spans within the bounded shutdown budget while preserving the exit code.
    let exit_code = match run_server_blocking(state) {
        Ok(exit) => exit.into(),
        Err(err) => {
            tracing::error!(error = %err, "web service exited with error");
            write_stderr_error(ErrorCode::Io, &err.to_string(), None);
            Exit::Runtime.into()
        }
    };

    #[cfg(feature = "otel")]
    if let Some(guard) = otel_guard
        && let Err(err) = guard.shutdown_blocking()
    {
        tracing::warn!(error = %err, "otel tracer provider shutdown returned an error");
    }

    exit_code
}
