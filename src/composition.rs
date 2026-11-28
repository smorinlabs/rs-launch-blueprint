//! Composition root wiring workspace packages together (`R02`).

use std::process::ExitCode;

use rs_launch_blueprint_core::WorkspaceInfo;

/// Return static metadata describing this compiled workspace build.
#[must_use]
pub const fn workspace_info() -> WorkspaceInfo {
    WorkspaceInfo::new(
        env!("CARGO_PKG_NAME"),
        crate::VERSION,
        cfg!(feature = "web"),
    )
}

/// Dispatch the CLI front end with the workspace composition descriptor.
pub fn run_cli(args: &[String]) -> ExitCode {
    rs_launch_blueprint_cli::run(workspace_info(), args)
}

/// Dispatch the optional web service stub (`web` feature required).
#[cfg(feature = "web")]
pub fn run_web_stub(args: &[String]) -> ExitCode {
    rs_launch_blueprint_web::serve_stub(workspace_info(), args)
}
