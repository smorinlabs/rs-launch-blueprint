//! Standalone Rust library facade for `rs-launch-blueprint` (`OV-18`, `R04`).
//!
//! This crate is a pure `[lib]` package with zero CLI (`clap`, `inquire`, `arboard`, `anyhow`)
//! and zero web (`axum`, `tokio`, `opentelemetry`) dependencies. Add it to any Rust project with
//! `cargo add rs-launch-blueprint` (or `--no-default-features` for the minimal domain-only core).
//!
//! All implementation modules are private and the curated public surface is re-exported from this
//! crate root (`R04`).
//!
//! # Feature flags
//!
//! - `http` (default): blocking HTTP [`ProjectsPort`] adapter ([`HttpProjectsPort`]) backed by
//!   `ureq` plus [`production_service`].
//! - `config` (default): XDG path discovery ([`Paths`]), layered TOML configuration loading and
//!   editing, and file-backed [`FileCredentialStore`].
//! - `keychain`: optional native OS keychain [`CredentialStore`] ([`KeychainCredentialStore`]).
//! - `mock`: enables `mockall`-generated [`MockProjectsPort`].
//!
//! # Examples
//!
//! ```
//! use rs_launch_blueprint::{Project, ProjectQuery, in_memory_service, workspace_info};
//!
//! let info = workspace_info();
//! assert_eq!(info.version, rs_launch_blueprint::VERSION);
//! assert_eq!(info.package, "rs-launch-blueprint");
//!
//! let service = in_memory_service([Project {
//!     id: "1".to_owned(),
//!     name: "Demo".to_owned(),
//!     workspace: None,
//! }]);
//! assert_eq!(service.list_projects(&ProjectQuery::default()).unwrap().len(), 1);
//! ```
//!
//! Private modules cannot be deep-imported by external consumers (`R04`):
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint::internal::InternalMarker;
//! let _ = std::mem::size_of::<InternalMarker>();
//! ```
//!
//! ```compile_fail,E0603
//! let _ = rs_launch_blueprint::composition::workspace_info();
//! ```

mod composition;
#[cfg(feature = "http")]
mod http_adapter;
mod internal;
#[cfg(feature = "keychain")]
mod keychain;

/// The version of this library package, from `Cargo.toml` (`R22`).
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(feature = "config")]
pub use composition::default_credential_store;
#[cfg(feature = "keychain")]
pub use composition::keychain_credential_store;
#[cfg(feature = "http")]
pub use composition::production_service;
pub use composition::{
    DEFAULT_API_BASE_URL, build_projects_service, in_memory_service, workspace_info,
};
#[cfg(feature = "http")]
pub use http_adapter::{DEFAULT_HTTP_TIMEOUT, HeaderInjector, HttpProjectsPort};
#[cfg(feature = "keychain")]
pub use keychain::KeychainCredentialStore;
#[cfg(feature = "mock")]
pub use rs_launch_blueprint_core::MockProjectsPort;
pub use rs_launch_blueprint_core::{
    AuthError, CORE_NAME, Check, CheckStatus, ConfigError, CreateProjectInput, CredentialStore,
    CredentialWarning, CredentialWarningKind, DEFAULT_PROJECT_LIMIT, Diagnostics,
    DiagnosticsContext, DomainError, ErasedProjectsService, ErrorBody, ErrorCode, ErrorEnvelope,
    InMemoryCredentialStore, InMemoryProjectsPort, PermissionCheck, PortCall, PortError, Project,
    ProjectQuery, ProjectsPort, ProjectsService, RecordingPort, ResolvedToken, TOKEN_ENV_VAR,
    Token, TokenResolution, TokenResolutionInputs, TokenSource, WorkspaceInfo,
    assert_projects_port_contract, draining_diagnostics, inspect_file_permissions, resolve_token,
    run_diagnostics,
};
#[cfg(feature = "config")]
pub use rs_launch_blueprint_core::{
    CONFIG_FILE_NAME, CRASH_LOG_FILE_NAME, CREDENTIALS_FILE_NAME, ColorPreference,
    ConfigDiscoveryInputs, ConfigFile, ConfigOverrides, ConfigSource, ConfigTier, ConfigWarning,
    ConfigWarningKind, ExplicitOrigin, FileCredentialStore, FileLogFormat, LOG_FILE_NAME,
    LoadedConfig, LogLevel, LoggingConfig, MERGE_STRATEGY_DOC, OutputConfig, OutputFormat,
    PRECEDENCE_CHAIN_DOC, PROJECT_CONFIG_DIR, Paths, TOOL_NAME, UnvalidatedConfig, ValidConfig,
    ValidationIssue, ValidationReport, WRITABLE_KEYS, discover_config_sources,
    discover_project_config_file, discover_system_config_files, get_config_value, load_config,
    merge_tables_recursive, read_config_file_key, set_config_value, validate_config_assignment,
};
