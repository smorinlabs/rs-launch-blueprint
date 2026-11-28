//! Layered TOML merging, error-tolerant loading, and structured warnings (`R54`, `R55`, `R56`).

use std::fmt;
use std::fs;
use std::io;
use std::path::PathBuf;

use crate::config::discovery::{
    ConfigDiscoveryInputs, ConfigSource, ConfigTier, discover_config_sources,
};
use crate::config::schema::{UnvalidatedConfig, ValidConfig};
use crate::config::validate::{sanitize_table, validate_table};
use crate::error::ConfigError;

/// Classification of non-fatal warnings collected while loading configuration (`R54`, `R55`, `R56`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ConfigWarningKind {
    /// Explicit `--config` or `RSLBP_CONFIG` file did not exist; defaults applied (`R55` F235).
    MissingExplicitFile,
    /// Discovered config file could not be read; skipped (`R54` AC12b).
    UnreadableDiscoveredFile {
        /// Filesystem I/O error detail.
        detail: String,
    },
    /// Discovered config file contained invalid TOML; skipped (`R54` AC12b).
    UnparsableDiscoveredFile {
        /// TOML parse error detail.
        detail: String,
    },
    /// A key's value failed schema validation; fell back to lower tier or default (`R55` F238).
    InvalidValue {
        /// Validation diagnostic message.
        detail: String,
    },
    /// An unrecognized configuration key was ignored (`R55` F236).
    UnknownKey,
    /// A prohibited secret key was found in a config file and ignored (`R56`).
    ProhibitedSecretKey,
}

/// Structured non-fatal configuration warning returned as data (library never writes to stderr).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigWarning {
    /// Configuration file that triggered the warning.
    pub path: PathBuf,
    /// Optional dotted key name associated with the warning.
    pub key: Option<String>,
    /// Warning classification.
    pub kind: ConfigWarningKind,
}

impl fmt::Display for ConfigWarning {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self.kind {
            ConfigWarningKind::MissingExplicitFile => write!(
                f,
                "explicit config file '{}' does not exist; using defaults",
                self.path.display()
            ),
            ConfigWarningKind::UnreadableDiscoveredFile { detail } => write!(
                f,
                "skipping unreadable config file '{}': {detail}",
                self.path.display()
            ),
            ConfigWarningKind::UnparsableDiscoveredFile { detail } => write!(
                f,
                "skipping invalid TOML in config file '{}': {detail}",
                self.path.display()
            ),
            ConfigWarningKind::InvalidValue { detail } => {
                let key = self.key.as_deref().unwrap_or("<root>");
                write!(
                    f,
                    "ignoring invalid value for '{key}' in '{}': {detail}",
                    self.path.display()
                )
            }
            ConfigWarningKind::UnknownKey => {
                let key = self.key.as_deref().unwrap_or("<unknown>");
                write!(
                    f,
                    "ignoring unknown config key '{key}' in '{}'",
                    self.path.display()
                )
            }
            ConfigWarningKind::ProhibitedSecretKey => {
                let key = self.key.as_deref().unwrap_or("token");
                write!(
                    f,
                    "ignoring prohibited secret key '{key}' in '{}'; supply credentials via a token file, RSLBP_TOKEN, or a dedicated credential store",
                    self.path.display()
                )
            }
        }
    }
}

/// Output of [`load_config`]: validated config, contributing sources, and collected warnings.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoadedConfig {
    /// Merged and schema-validated configuration.
    pub config: ValidConfig,
    /// Configuration sources that were read and merged, in precedence order.
    pub sources: Vec<ConfigSource>,
    /// Non-fatal warnings accumulated across all layers.
    pub warnings: Vec<ConfigWarning>,
}

/// Recursively merge `overlay` into `base`: TOML tables merge recursively while scalars and
/// arrays replace wholesale (`R54` AC11).
pub fn merge_tables_recursive(base: &mut toml::Table, overlay: toml::Table) {
    for (key, value) in overlay {
        match (base.get_mut(&key), value) {
            (Some(toml::Value::Table(base_table)), toml::Value::Table(overlay_table)) => {
                merge_tables_recursive(base_table, overlay_table);
            }
            (_, other) => {
                base.insert(key, other);
            }
        }
    }
}

/// Discover, load, sanitize per-layer, recursively merge, and validate configuration (`R54`–`R56`).
///
/// Provenance rules (`R55` clauses 1–4):
/// - Missing explicit file: warns once and returns built-in defaults.
/// - Unreadable explicit file: fails with [`ConfigError::Unreadable`] (`RSLB104`).
/// - Unparsable explicit file: fails with [`ConfigError::Unparsable`] (`RSLB202`).
/// - Missing discovered file: silently ignored.
/// - Unreadable or unparsable discovered file: warns and skips that layer.
/// - Invalid leaf, unknown key, or prohibited secret key in any layer: warns and strips the
///   offending key BEFORE merging so lower tiers retain precedence over built-in defaults.
pub fn load_config(inputs: &ConfigDiscoveryInputs<'_>) -> Result<LoadedConfig, ConfigError> {
    let discovered = discover_config_sources(inputs);
    let mut merged = toml::Table::new();
    let mut loaded_sources = Vec::new();
    let mut warnings = Vec::new();

    for source in discovered {
        let is_explicit = matches!(source.tier, ConfigTier::Explicit(_));
        let raw = match fs::read_to_string(&source.path) {
            Ok(content) => content,
            Err(err) if err.kind() == io::ErrorKind::NotFound => {
                if is_explicit {
                    warnings.push(ConfigWarning {
                        path: source.path,
                        key: None,
                        kind: ConfigWarningKind::MissingExplicitFile,
                    });
                }
                continue;
            }
            Err(err) => {
                if is_explicit {
                    return Err(ConfigError::Unreadable {
                        path: source.path,
                        source: err,
                    });
                }
                warnings.push(ConfigWarning {
                    path: source.path,
                    key: None,
                    kind: ConfigWarningKind::UnreadableDiscoveredFile {
                        detail: err.to_string(),
                    },
                });
                continue;
            }
        };

        let table: toml::Table = match toml::from_str(&raw) {
            Ok(parsed) => parsed,
            Err(err) => {
                if is_explicit {
                    return Err(ConfigError::Unparsable {
                        path: source.path,
                        detail: err.message().to_owned(),
                        span: err.span(),
                    });
                }
                warnings.push(ConfigWarning {
                    path: source.path,
                    key: None,
                    kind: ConfigWarningKind::UnparsableDiscoveredFile {
                        detail: err.message().to_owned(),
                    },
                });
                continue;
            }
        };

        // Validate and strip invalid/unknown/secret keys per layer BEFORE merging so a faulty
        // project-tier leaf falls back to user/system tiers rather than built-in defaults (R54 AC12a).
        let layer_report = validate_table(&table);
        for secret_key in &layer_report.prohibited_secret_keys {
            warnings.push(ConfigWarning {
                path: source.path.clone(),
                key: Some(secret_key.clone()),
                kind: ConfigWarningKind::ProhibitedSecretKey,
            });
        }
        for issue in &layer_report.issues {
            warnings.push(ConfigWarning {
                path: source.path.clone(),
                key: Some(issue.path.clone()),
                kind: ConfigWarningKind::InvalidValue {
                    detail: issue.message.clone(),
                },
            });
        }
        for unknown in &layer_report.unknown_keys {
            warnings.push(ConfigWarning {
                path: source.path.clone(),
                key: Some(unknown.clone()),
                kind: ConfigWarningKind::UnknownKey,
            });
        }

        let sanitized = sanitize_table(&table, &layer_report);
        merge_tables_recursive(&mut merged, sanitized);
        loaded_sources.push(source);
    }

    let final_report = UnvalidatedConfig::from_table(merged).validate();
    Ok(LoadedConfig {
        config: final_report.config,
        sources: loaded_sources,
        warnings,
    })
}
