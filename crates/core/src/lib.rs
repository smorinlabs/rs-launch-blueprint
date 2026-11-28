//! Core library crate for `rs-launch-blueprint`.
//!
//! All internal modules are private and re-exported through the curated root surface (`R04`).
//! `crates/core` is strictly transport- and runtime-agnostic: it contains zero dependencies on
//! `tokio`, `axum`, `clap`, `anyhow`, `ureq`, `tracing-subscriber`, or OS keyring crates (`R01`,
//! `R02`, `R05`).
//!
//! # Examples
//!
//! ```
//! use rs_launch_blueprint_core::{
//!     CORE_NAME, InMemoryProjectsPort, Project, ProjectQuery, ProjectsService, WorkspaceInfo,
//! };
//!
//! let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", false);
//! assert_eq!(CORE_NAME, "rs-launch-blueprint-core");
//! assert_eq!(info.package, "rs-launch-blueprint");
//!
//! let port = InMemoryProjectsPort::with_projects([Project {
//!     id: "1".to_owned(),
//!     name: "Demo".to_owned(),
//!     workspace: None,
//! }]);
//! let service = ProjectsService::new(port);
//! assert_eq!(service.list_projects(&ProjectQuery::default()).unwrap().len(), 1);
//! ```
//!
//! Internal modules cannot be imported directly by external consumers (`R04`):
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_core::metadata::WorkspaceInfo;
//! let _ = WorkspaceInfo::new("a", "0.1.0", false);
//! ```
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_core::ports::ProjectsPort;
//! ```
//!
//! Incomplete implementations of [`ProjectsPort`] fail at compile time (`R01`):
//!
//! ```compile_fail,E0046
//! use rs_launch_blueprint_core::{PortError, Project, ProjectQuery, ProjectsPort};
//!
//! struct Incomplete;
//! impl ProjectsPort for Incomplete {
//!     fn list(&self, _query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
//!         Ok(Vec::new())
//!     }
//! }
//! ```

mod clipboard;
mod config;
mod error;
mod metadata;
mod models;
mod paths;
mod ports;
mod secrets;
mod service;

pub use clipboard::{ClipboardError, ClipboardPort, FailingClipboard, RecordingClipboard};
pub use config::{
    ColorPreference, ConfigDiscoveryInputs, ConfigFile, ConfigOverrides, ConfigSource, ConfigTier,
    ConfigWarning, ConfigWarningKind, ExplicitOrigin, FileLogFormat, LoadedConfig, LogLevel,
    LoggingConfig, MERGE_STRATEGY_DOC, OutputConfig, OutputFormat, PRECEDENCE_CHAIN_DOC,
    UnvalidatedConfig, ValidConfig, ValidationIssue, ValidationReport, WRITABLE_KEYS,
    discover_config_sources, discover_project_config_file, discover_system_config_files,
    get_config_value, load_config, merge_tables_recursive, read_config_file_key, set_config_value,
    validate_config_assignment,
};
pub use error::{
    AuthError, ConfigError, DomainError, ErrorBody, ErrorCode, ErrorEnvelope, Exit, PortError,
};
pub use metadata::{CORE_NAME, WorkspaceInfo};
pub use models::{CreateProjectInput, DEFAULT_PROJECT_LIMIT, Project, ProjectQuery};
pub use paths::{
    CONFIG_FILE_NAME, CRASH_LOG_FILE_NAME, CREDENTIALS_FILE_NAME, LOG_FILE_NAME,
    PROJECT_CONFIG_DIR, Paths, TOOL_NAME,
};
#[cfg(feature = "mock")]
pub use ports::MockProjectsPort;
pub use ports::{
    InMemoryProjectsPort, PortCall, ProjectsPort, RecordingPort, assert_projects_port_contract,
};
pub use secrets::{
    CredentialStore, CredentialWarning, CredentialWarningKind, FileCredentialStore,
    InMemoryCredentialStore, PermissionCheck, ResolvedToken, TOKEN_ENV_VAR, Token, TokenResolution,
    TokenResolutionInputs, TokenSource, inspect_file_permissions, resolve_token,
};
pub use service::{ErasedProjectsService, ProjectsService};
