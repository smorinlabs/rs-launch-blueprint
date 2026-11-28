//! Deterministic per-key validation and table sanitization (`R55`, `R56`).

use std::num::NonZeroU32;
use std::path::PathBuf;

use crate::config::schema::{
    ColorPreference, ConfigFile, FileLogFormat, LogLevel, OutputFormat, ValidConfig,
    ValidationIssue, ValidationReport,
};

/// Return `true` if any dotted segment of `key_path` names a prohibited secret channel (`R56`).
pub(crate) fn is_prohibited_secret_key(key_path: &str) -> bool {
    key_path.split('.').any(|segment| {
        let norm = segment.trim().to_ascii_lowercase().replace('-', "_");
        matches!(
            norm.as_str(),
            "token" | "password" | "secret" | "api_key" | "apikey" | "credential" | "authorization"
        ) || norm.ends_with("_token")
            || norm.ends_with("_password")
            || norm.ends_with("_secret")
            || norm.ends_with("_api_key")
    })
}

/// Validate a raw `toml::Table` key-by-key in deterministic sorted order (`R55`).
///
/// Never echoes values of prohibited secret keys. Reports non-table `[output]` / `[logging]`
/// sections explicitly (`R55` R8a/R8b).
pub(crate) fn validate_table(table: &toml::Table) -> ValidationReport {
    let mut cfg = ConfigFile::default();
    let mut issues = Vec::new();
    let mut unknown_keys = Vec::new();
    let mut prohibited_secret_keys = Vec::new();

    for (key, value) in table {
        match key.as_str() {
            "output" => validate_output_section(
                value,
                &mut cfg,
                &mut issues,
                &mut unknown_keys,
                &mut prohibited_secret_keys,
            ),
            "logging" => validate_logging_section(
                value,
                &mut cfg,
                &mut issues,
                &mut unknown_keys,
                &mut prohibited_secret_keys,
            ),
            other => collect_unknown_or_secret(
                other,
                value,
                &mut unknown_keys,
                &mut prohibited_secret_keys,
            ),
        }
    }

    ValidationReport {
        config: ValidConfig::from_validated(cfg),
        issues,
        unknown_keys,
        prohibited_secret_keys,
    }
}

fn validate_output_section(
    value: &toml::Value,
    cfg: &mut ConfigFile,
    issues: &mut Vec<ValidationIssue>,
    unknown_keys: &mut Vec<String>,
    prohibited_secret_keys: &mut Vec<String>,
) {
    let Some(section) = value.as_table() else {
        issues.push(ValidationIssue {
            path: "output".to_owned(),
            message: format!(
                "expected a TOML table for [output], found {}",
                value.type_str()
            ),
        });
        return;
    };

    for (key, val) in section {
        match key.as_str() {
            "color" => match val.clone().try_into::<ColorPreference>() {
                Ok(parsed) => cfg.output.color = parsed,
                Err(err) => issues.push(ValidationIssue {
                    path: "output.color".to_owned(),
                    message: err.message().to_owned(),
                }),
            },
            "format" => match val.clone().try_into::<OutputFormat>() {
                Ok(parsed) => cfg.output.format = parsed,
                Err(err) => issues.push(ValidationIssue {
                    path: "output.format".to_owned(),
                    message: err.message().to_owned(),
                }),
            },
            "limit" => match val.clone().try_into::<NonZeroU32>() {
                Ok(parsed) => cfg.output.limit = Some(parsed),
                Err(_) => issues.push(ValidationIssue {
                    path: "output.limit".to_owned(),
                    message: "expected a positive integer (1..=4294967295)".to_owned(),
                }),
            },
            other => {
                let full_path = format!("output.{other}");
                collect_unknown_or_secret(&full_path, val, unknown_keys, prohibited_secret_keys);
            }
        }
    }
}

fn validate_logging_section(
    value: &toml::Value,
    cfg: &mut ConfigFile,
    issues: &mut Vec<ValidationIssue>,
    unknown_keys: &mut Vec<String>,
    prohibited_secret_keys: &mut Vec<String>,
) {
    let Some(section) = value.as_table() else {
        issues.push(ValidationIssue {
            path: "logging".to_owned(),
            message: format!(
                "expected a TOML table for [logging], found {}",
                value.type_str()
            ),
        });
        return;
    };

    for (key, val) in section {
        match key.as_str() {
            "file" => match val.as_str() {
                Some(raw) => {
                    cfg.logging.file = if raw.is_empty() {
                        None
                    } else {
                        Some(PathBuf::from(raw))
                    };
                }
                None => issues.push(ValidationIssue {
                    path: "logging.file".to_owned(),
                    message: format!("expected a string path, found {}", val.type_str()),
                }),
            },
            "file-format" => match val.clone().try_into::<FileLogFormat>() {
                Ok(parsed) => cfg.logging.file_format = parsed,
                Err(err) => issues.push(ValidationIssue {
                    path: "logging.file-format".to_owned(),
                    message: err.message().to_owned(),
                }),
            },
            "file-level" => match val.clone().try_into::<LogLevel>() {
                Ok(parsed) => cfg.logging.file_level = Some(parsed),
                Err(err) => issues.push(ValidationIssue {
                    path: "logging.file-level".to_owned(),
                    message: err.message().to_owned(),
                }),
            },
            "level" => match val.clone().try_into::<LogLevel>() {
                Ok(parsed) => cfg.logging.level = parsed,
                Err(err) => issues.push(ValidationIssue {
                    path: "logging.level".to_owned(),
                    message: err.message().to_owned(),
                }),
            },
            other => {
                let full_path = format!("logging.{other}");
                collect_unknown_or_secret(&full_path, val, unknown_keys, prohibited_secret_keys);
            }
        }
    }
}

fn collect_unknown_or_secret(
    path: &str,
    value: &toml::Value,
    unknown_keys: &mut Vec<String>,
    prohibited_secret_keys: &mut Vec<String>,
) {
    if is_prohibited_secret_key(path) {
        prohibited_secret_keys.push(path.to_owned());
        return;
    }
    if let Some(sub) = value.as_table()
        && !sub.is_empty()
    {
        for (k, v) in sub {
            let child = format!("{path}.{k}");
            collect_unknown_or_secret(&child, v, unknown_keys, prohibited_secret_keys);
        }
        return;
    }
    unknown_keys.push(path.to_owned());
}

/// Remove every invalid, unknown, or prohibited secret key from `table` so that merging a
/// higher-precedence layer falls back cleanly to lower tiers rather than built-in defaults
/// (`R54` AC12a, `R55` F238).
pub(crate) fn sanitize_table(table: &toml::Table, report: &ValidationReport) -> toml::Table {
    let mut cleaned = table.clone();
    for issue in &report.issues {
        remove_dotted_path(&mut cleaned, &issue.path);
    }
    for key in &report.unknown_keys {
        remove_dotted_path(&mut cleaned, key);
    }
    for secret_key in &report.prohibited_secret_keys {
        remove_dotted_path(&mut cleaned, secret_key);
    }
    cleaned
}

fn remove_dotted_path(table: &mut toml::Table, path: &str) {
    let segments: Vec<&str> = path.split('.').collect();
    remove_segments(table, &segments);
}

fn remove_segments(table: &mut toml::Table, segments: &[&str]) {
    let Some((&first, rest)) = segments.split_first() else {
        return;
    };
    if rest.is_empty() {
        table.remove(first);
        return;
    }
    let remove_parent = match table.get_mut(first) {
        Some(toml::Value::Table(child)) => {
            remove_segments(child, rest);
            child.is_empty()
        }
        _ => false,
    };
    if remove_parent {
        table.remove(first);
    }
}
