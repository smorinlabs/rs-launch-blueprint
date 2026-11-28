//! Composition root wiring workspace packages, ports, credential stores, and services (`R01`,
//! `R02`, `R56`).

use std::process::ExitCode;
use std::sync::Arc;

#[cfg(feature = "keychain")]
use rs_launch_blueprint_core::AuthError;
use rs_launch_blueprint_core::{
    ErasedProjectsService, FileCredentialStore, InMemoryProjectsPort, Paths, Project, ProjectsPort,
    ProjectsService, Token, WorkspaceInfo,
};

use crate::http_adapter::HttpProjectsPort;
#[cfg(feature = "keychain")]
use crate::keychain::KeychainCredentialStore;

/// Default remote API base URL used by production compositions when not overridden.
pub const DEFAULT_API_BASE_URL: &str = "https://api.example.com/v1";

/// Return static metadata describing this compiled workspace build.
#[must_use]
pub const fn workspace_info() -> WorkspaceInfo {
    WorkspaceInfo::new(
        env!("CARGO_PKG_NAME"),
        crate::VERSION,
        cfg!(feature = "web"),
    )
}

/// Construct an [`ErasedProjectsService`] from any concrete [`ProjectsPort`] implementation (`R01`).
///
/// Both the CLI and optional web service share this erased service type.
#[must_use]
pub fn build_projects_service(port: Arc<dyn ProjectsPort>) -> ErasedProjectsService {
    ProjectsService::new(port)
}

/// Wire the production [`ErasedProjectsService`] backed by [`HttpProjectsPort`].
#[must_use]
pub fn production_service(base_url: impl Into<String>, token: Token) -> ErasedProjectsService {
    let port: Arc<dyn ProjectsPort> = Arc::new(HttpProjectsPort::new(base_url, token));
    build_projects_service(port)
}

/// Wire an in-memory [`ErasedProjectsService`] seeded with `projects` for demos and tests.
#[must_use]
pub fn in_memory_service(projects: impl IntoIterator<Item = Project>) -> ErasedProjectsService {
    let port: Arc<dyn ProjectsPort> = Arc::new(InMemoryProjectsPort::with_projects(projects));
    build_projects_service(port)
}

/// Build the default `0600` file-backed credential store under [`Paths::credentials_file`] (`R56`).
#[must_use]
pub fn default_credential_store(paths: &Paths) -> FileCredentialStore {
    FileCredentialStore::new(paths.credentials_file())
}

/// Build the native OS keychain credential store (`keychain` feature required, `R56`).
#[cfg(feature = "keychain")]
pub fn keychain_credential_store(
    service: impl Into<String>,
    user: impl Into<String>,
) -> Result<KeychainCredentialStore, AuthError> {
    KeychainCredentialStore::native(service, user)
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
