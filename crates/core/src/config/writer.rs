//! Decor-preserving TOML configuration mutations via `toml_edit` (`R52`, `R56`).

use std::fs;
use std::io;
use std::num::NonZeroU32;
use std::path::Path;
use std::str::FromStr;

use crate::config::schema::{ColorPreference, FileLogFormat, LogLevel, OutputFormat, ValidConfig};
use crate::config::validate::is_prohibited_secret_key;
use crate::error::ConfigError;
use crate::secrets::write_atomic_0600;

/// Schema-checked dotted keys accepted by [`set_config_value`] and [`get_config_value`].
pub const WRITABLE_KEYS: &[&str] = &[
    "output.format",
    "output.color",
    "output.limit",
    "logging.level",
    "logging.file",
    "logging.file-format",
    "logging.file-level",
];

/// Read a typed dotted key from a [`ValidConfig`] for `config get <key>`.
pub fn get_config_value(config: &ValidConfig, key: &str) -> Result<Option<String>, ConfigError> {
    if is_prohibited_secret_key(key) {
        return Err(ConfigError::ProhibitedSecretChannel {
            key: key.to_owned(),
        });
    }
    let cfg = config.as_config();
    match key {
        "output.format" => Ok(Some(cfg.output.format.as_str().to_owned())),
        "output.color" => Ok(Some(cfg.output.color.as_str().to_owned())),
        "output.limit" => Ok(cfg.output.limit.map(|n| n.to_string())),
        "logging.level" => Ok(Some(cfg.logging.level.as_str().to_owned())),
        "logging.file" => Ok(cfg
            .logging
            .file
            .as_ref()
            .map(|p| p.to_string_lossy().into_owned())),
        "logging.file-format" => Ok(Some(cfg.logging.file_format.as_str().to_owned())),
        "logging.file-level" => Ok(cfg.logging.file_level.map(|l| l.as_str().to_owned())),
        _ => Err(ConfigError::UnknownKey {
            key: key.to_owned(),
            valid_keys: WRITABLE_KEYS.to_vec(),
        }),
    }
}

/// Validate and canonicalize one dotted `(key, raw_value)` assignment without touching disk.
///
/// Refuses prohibited secret keys with [`ConfigError::ProhibitedSecretChannel`] (`RSLB204`) and
/// unknown/invalid keys with `RSLB203`.
pub fn validate_config_assignment(key: &str, raw_value: &str) -> Result<String, ConfigError> {
    if is_prohibited_secret_key(key) {
        return Err(ConfigError::ProhibitedSecretChannel {
            key: key.to_owned(),
        });
    }
    let (_, _, _, canonical) = coerce_key_value(key, raw_value)?;
    Ok(canonical)
}

/// Read the raw value currently stored for dotted `key` in a single TOML file at `path`.
///
/// Returns `Ok(None)` when `path` does not exist or does not explicitly set `key`.
pub fn read_config_file_key(path: &Path, key: &str) -> Result<Option<String>, ConfigError> {
    let raw = match fs::read_to_string(path) {
        Ok(content) => content,
        Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok(None),
        Err(source) => {
            return Err(ConfigError::Unreadable {
                path: path.to_path_buf(),
                source,
            });
        }
    };
    let table: toml::Table = toml::from_str(&raw).map_err(|err| ConfigError::Unparsable {
        path: path.to_path_buf(),
        detail: err.message().to_owned(),
        span: err.span(),
    })?;
    let Some((section, field)) = key.split_once('.') else {
        return Ok(None);
    };
    let Some(val) = table
        .get(section)
        .and_then(toml::Value::as_table)
        .and_then(|t| t.get(field))
    else {
        return Ok(None);
    };
    let rendered = match val {
        toml::Value::String(s) => s.clone(),
        toml::Value::Integer(n) => n.to_string(),
        other => other.to_string(),
    };
    Ok(Some(rendered))
}

/// Update one dotted configuration key in `path` while preserving all comments, whitespace, and
/// key ordering (`R52` AC3), writing atomically at mode `0600` (`R52` AC5).
///
/// Refuses prohibited secret keys with [`ConfigError::ProhibitedSecretChannel`] (`RSLB204`, `R56`
/// AC7) before touching the filesystem, and refuses to modify a corrupt existing file (`R52` AC6).
/// Returns the canonical coerced string representation of the stored value.
pub fn set_config_value(path: &Path, key: &str, raw_value: &str) -> Result<String, ConfigError> {
    if is_prohibited_secret_key(key) {
        return Err(ConfigError::ProhibitedSecretChannel {
            key: key.to_owned(),
        });
    }

    let (section, field, new_value, canonical) = coerce_key_value(key, raw_value)?;

    let mut doc =
        match fs::read_to_string(path) {
            Ok(existing) => existing.parse::<toml_edit::DocumentMut>().map_err(|err| {
                ConfigError::Unparsable {
                    path: path.to_path_buf(),
                    detail: err.message().to_owned(),
                    span: err.span(),
                }
            })?,
            Err(err) if err.kind() == io::ErrorKind::NotFound => toml_edit::DocumentMut::new(),
            Err(source) => {
                return Err(ConfigError::Unreadable {
                    path: path.to_path_buf(),
                    source,
                });
            }
        };

    if !doc.contains_key(section) {
        doc[section] = toml_edit::Item::Table(toml_edit::Table::new());
    }

    let Some(table) = doc[section].as_table_mut() else {
        return Err(ConfigError::InvalidValue {
            path: Some(path.to_path_buf()),
            key: section.to_owned(),
            detail: format!("existing '{section}' entry is not a TOML table"),
        });
    };

    // R52 decor-preservation recipe: copy the existing Value's decor so inline trailing comments
    // survive in-place replacement.
    if let Some(existing_item) = table.get_mut(field) {
        if let Some(existing_val) = existing_item.as_value_mut() {
            let decor = existing_val.decor().clone();
            *existing_val = new_value;
            *existing_val.decor_mut() = decor;
        } else {
            *existing_item = toml_edit::value(new_value);
        }
    } else {
        table.insert(field, toml_edit::value(new_value));
    }

    let rendered = doc.to_string();
    write_atomic_0600(path, rendered.as_bytes()).map_err(|source| ConfigError::WriteFailed {
        path: path.to_path_buf(),
        source,
    })?;

    Ok(canonical)
}

fn coerce_key_value(
    key: &str,
    raw_value: &str,
) -> Result<(&'static str, &'static str, toml_edit::Value, String), ConfigError> {
    match key {
        "output.format" => {
            let parsed = OutputFormat::from_str(raw_value)?;
            let s = parsed.as_str();
            Ok(("output", "format", toml_edit::Value::from(s), s.to_owned()))
        }
        "output.color" => {
            let parsed = ColorPreference::from_str(raw_value)?;
            let s = parsed.as_str();
            Ok(("output", "color", toml_edit::Value::from(s), s.to_owned()))
        }
        "output.limit" => {
            let parsed =
                raw_value
                    .trim()
                    .parse::<NonZeroU32>()
                    .map_err(|_| ConfigError::InvalidValue {
                        path: None,
                        key: "output.limit".to_owned(),
                        detail: format!(
                            "expected a positive integer (1..=4294967295) (got '{raw_value}')"
                        ),
                    })?;
            Ok((
                "output",
                "limit",
                toml_edit::Value::from(i64::from(parsed.get())),
                parsed.to_string(),
            ))
        }
        "logging.level" => {
            let parsed = LogLevel::from_str(raw_value)?;
            let s = parsed.as_str();
            Ok(("logging", "level", toml_edit::Value::from(s), s.to_owned()))
        }
        "logging.file" => Ok((
            "logging",
            "file",
            toml_edit::Value::from(raw_value),
            raw_value.to_owned(),
        )),
        "logging.file-format" => {
            let parsed = FileLogFormat::from_str(raw_value)?;
            let s = parsed.as_str();
            Ok((
                "logging",
                "file-format",
                toml_edit::Value::from(s),
                s.to_owned(),
            ))
        }
        "logging.file-level" => {
            let parsed = LogLevel::from_str(raw_value).map_err(|_| ConfigError::InvalidValue {
                path: None,
                key: "logging.file-level".to_owned(),
                detail: format!(
                    "expected one of: off, error, warn, info, debug, trace (got '{raw_value}')"
                ),
            })?;
            let s = parsed.as_str();
            Ok((
                "logging",
                "file-level",
                toml_edit::Value::from(s),
                s.to_owned(),
            ))
        }
        _ => Err(ConfigError::UnknownKey {
            key: key.to_owned(),
            valid_keys: WRITABLE_KEYS.to_vec(),
        }),
    }
}
