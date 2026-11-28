//! Minimal P04 web service stub (`P08` replaces this with `axum` + `tokio`).

use std::io::{self, Write};
use std::process::ExitCode;

use rs_launch_blueprint_core::WorkspaceInfo;

/// Execute the P04 skeleton `rslbp-serve` binary entrypoint.
///
/// Full HTTP routing, middleware, and OpenAPI support land in `P08`–`P09`.
pub fn serve_stub(info: WorkspaceInfo, args: &[String]) -> ExitCode {
    tracing::debug!(
        argc = args.len(),
        package = info.package,
        web_enabled = info.web_enabled,
        "dispatching web stub"
    );
    let mut stdout = io::stdout().lock();
    let result = match args.first().map(String::as_str) {
        Some("-V" | "--version") => writeln!(stdout, "rslbp-serve {}", info.version),
        Some("-h" | "--help") => writeln!(
            stdout,
            "rslbp-serve {} — optional web service stub (full server lands in P08)",
            info.version
        ),
        None => writeln!(
            stdout,
            "rslbp-serve {} (web_enabled={})",
            info.version, info.web_enabled
        ),
        Some(flag) => {
            let mut stderr = io::stderr().lock();
            let _ = writeln!(
                stderr,
                "rslbp-serve: unrecognized argument `{flag}` (try --help)"
            );
            return ExitCode::from(2);
        }
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) if err.kind() == io::ErrorKind::BrokenPipe => ExitCode::SUCCESS,
        Err(_) => ExitCode::FAILURE,
    }
}

#[cfg(test)]
mod tests {
    use std::process::ExitCode;

    use rs_launch_blueprint_core::WorkspaceInfo;

    use super::serve_stub;

    #[test]
    fn serve_stub_handles_version_and_help() {
        let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", true);
        assert_eq!(
            serve_stub(info, &["--version".to_owned()]),
            ExitCode::SUCCESS
        );
        assert_eq!(serve_stub(info, &["--help".to_owned()]), ExitCode::SUCCESS);
    }
}
