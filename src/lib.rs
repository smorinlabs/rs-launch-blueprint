//! Public facade for `rs-launch-blueprint`.
//!
//! All implementation modules are private and the curated public surface is
//! re-exported from this file (`R04`).
//!
//! # Examples
//!
//! ```
//! let info = rs_launch_blueprint::workspace_info();
//! assert_eq!(info.version, rs_launch_blueprint::VERSION);
//! assert_eq!(info.package, "rs-launch-blueprint");
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
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint::http_adapter::HttpProjectsPort;
//! ```
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint::telemetry::JsonEvent;
//! ```

mod composition;
mod http_adapter;
mod internal;
#[cfg(feature = "keychain")]
mod keychain;
mod telemetry;

/// The version of this package, from `Cargo.toml` (`R22`).
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(feature = "keychain")]
pub use composition::keychain_credential_store;
#[cfg(feature = "web")]
pub use composition::run_web_stub;
pub use composition::{
    DEFAULT_API_BASE_URL, build_projects_service, default_credential_store, in_memory_service,
    production_service, run_cli, workspace_info,
};
pub use http_adapter::{DEFAULT_HTTP_TIMEOUT, HttpProjectsPort};
#[cfg(feature = "keychain")]
pub use keychain::KeychainCredentialStore;
#[cfg(feature = "mock")]
pub use rs_launch_blueprint_core::MockProjectsPort;
pub use rs_launch_blueprint_core::{
    AuthError, CONFIG_FILE_NAME, CORE_NAME, CRASH_LOG_FILE_NAME, CREDENTIALS_FILE_NAME,
    ColorPreference, ConfigDiscoveryInputs, ConfigError, ConfigFile, ConfigOverrides, ConfigSource,
    ConfigTier, ConfigWarning, ConfigWarningKind, CreateProjectInput, CredentialStore,
    CredentialWarning, CredentialWarningKind, DEFAULT_PROJECT_LIMIT, DomainError,
    ErasedProjectsService, ErrorBody, ErrorCode, ErrorEnvelope, Exit, ExplicitOrigin,
    FileCredentialStore, FileLogFormat, InMemoryCredentialStore, InMemoryProjectsPort,
    LOG_FILE_NAME, LoadedConfig, LogLevel, LoggingConfig, MERGE_STRATEGY_DOC, OutputConfig,
    OutputFormat, PRECEDENCE_CHAIN_DOC, PROJECT_CONFIG_DIR, Paths, PermissionCheck, PortCall,
    PortError, Project, ProjectQuery, ProjectsPort, ProjectsService, RecordingPort, ResolvedToken,
    TOKEN_ENV_VAR, TOOL_NAME, Token, TokenResolution, TokenResolutionInputs, TokenSource,
    UnvalidatedConfig, ValidConfig, ValidationIssue, ValidationReport, WRITABLE_KEYS,
    WorkspaceInfo, assert_projects_port_contract, discover_config_sources,
    discover_project_config_file, discover_system_config_files, get_config_value,
    inspect_file_permissions, load_config, merge_tables_recursive, resolve_token, set_config_value,
};
pub use telemetry::{
    HumanFields, JsonEvent, JsonFields, LevelLadderInput, LogFormat, Profile, REDACTED,
    ROTATE_BACKUP_COUNT, ROTATE_MAX_BYTES, ResolvedLogFormat, RotatingFile, SENSITIVE_KEY_PARTS,
    ServiceLogFormat, TelemetryHandles, TelemetryInit, build_scoped_subscriber, init_telemetry,
    is_sensitive_key, level_to_env_filter, level_to_filter, resolve_console_level,
    resolve_log_file, resolve_log_format,
};
