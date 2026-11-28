//! Layered TOML configuration schema, validation, discovery, loading, and decor-preserving
//! mutation (`R52`–`R56`).

mod discovery;
mod loader;
mod schema;
mod validate;
mod writer;

pub use discovery::{
    ConfigDiscoveryInputs, ConfigSource, ConfigTier, ExplicitOrigin, MERGE_STRATEGY_DOC,
    PRECEDENCE_CHAIN_DOC, discover_config_sources, discover_project_config_file,
    discover_system_config_files,
};
pub use loader::{
    ConfigWarning, ConfigWarningKind, LoadedConfig, load_config, merge_tables_recursive,
};
pub use schema::{
    ColorPreference, ConfigFile, ConfigOverrides, FileLogFormat, LogLevel, LoggingConfig,
    OutputConfig, OutputFormat, ResolvedLogFormat, ServiceLogFormat, UnvalidatedConfig,
    ValidConfig, ValidationIssue, ValidationReport,
};
pub use writer::{
    WRITABLE_KEYS, get_config_value, read_config_file_key, set_config_value,
    validate_config_assignment,
};
