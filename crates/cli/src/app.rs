//! Minimal P04 CLI entrypoint stub (`P07` replaces this with the full `clap` derive CLI).

use std::io::{self, Write};
use std::process::ExitCode;

use rs_launch_blueprint_core::WorkspaceInfo;

/// Execute the P04 skeleton CLI against the provided arguments.
///
/// Supports `-V`/`--version` and `-h`/`--help`; full CLI commands land in `P07`.
pub fn run(info: WorkspaceInfo, args: &[String]) -> ExitCode {
    tracing::debug!(argc = args.len(), package = info.package, "dispatching cli");
    let mut stdout = io::stdout().lock();
    let result = match args.first().map(String::as_str) {
        Some("-V" | "--version") => writeln!(stdout, "rslbp {}", info.version),
        Some("-h" | "--help") => writeln!(
            stdout,
            "rslbp {} — {} (workspace skeleton)\n\nUsage: rslbp [--version | --help]",
            info.version, info.package
        ),
        None => writeln!(stdout, "{} {}", info.package, info.version),
        Some(flag) => {
            let mut stderr = io::stderr().lock();
            let _ = writeln!(stderr, "rslbp: unrecognized argument `{flag}` (try --help)");
            return ExitCode::from(2);
        }
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        // R67: broken pipe on the result stream exits 0 silently.
        Err(err) if err.kind() == io::ErrorKind::BrokenPipe => ExitCode::SUCCESS,
        Err(_) => ExitCode::FAILURE,
    }
}

#[cfg(test)]
mod tests {
    use std::process::ExitCode;

    use rs_launch_blueprint_core::WorkspaceInfo;

    use super::run;

    #[test]
    fn version_and_help_succeed() {
        let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", false);
        assert_eq!(run(info, &["--version".to_owned()]), ExitCode::SUCCESS);
        assert_eq!(run(info, &["-h".to_owned()]), ExitCode::SUCCESS);
        assert_eq!(run(info, &[]), ExitCode::SUCCESS);
    }

    #[test]
    fn unknown_flag_returns_usage_exit_code() {
        let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", false);
        assert_eq!(run(info, &["--nope".to_owned()]), ExitCode::from(2));
    }
}
