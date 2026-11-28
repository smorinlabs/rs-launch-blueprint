//! Shared synchronous diagnostics contract used by both the CLI `diagnostics` command and the
//! web service `/readyz` probe (`R80` F329, `R02`, `R03`, `R05`).
//!
//! This module is the single source of truth for the diagnostic check list and check names.
//! Because `crates/core` is framework-agnostic, types here derive `serde::Serialize` only and
//! carry no HTTP or CLI attributes.

use std::path::Path;

use serde::Serialize;

use crate::metadata::VERSION;
use crate::secrets::TOKEN_ENV_VAR;

/// Outcome severity of a single diagnostic check (`R80`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum CheckStatus {
    /// Check passed without findings.
    Ok,
    /// Advisory finding that does not make the service unready.
    Warn,
    /// Blocking error that fails `/readyz` (`503`) and exits CLI diagnostics non-zero.
    Error,
}

impl CheckStatus {
    /// Return the canonical lowercase wire representation (`"ok"`, `"warn"`, `"error"`).
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Ok => "ok",
            Self::Warn => "warn",
            Self::Error => "error",
        }
    }
}

/// Single diagnostic check item (`R80`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Check {
    /// Stable literal check name (defined exclusively in this module).
    pub name: &'static str,
    /// Outcome status (`ok`, `warn`, or `error`).
    pub status: CheckStatus,
    /// Human-readable check detail.
    pub detail: String,
}

/// Ordered collection of diagnostic checks returned by [`run_diagnostics`] (`R80`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Diagnostics {
    /// Executed diagnostic checks in stable order.
    pub checks: Vec<Check>,
}

impl Diagnostics {
    /// Return `true` when at least one check reported [`CheckStatus::Error`].
    #[must_use]
    pub fn has_error(&self) -> bool {
        self.checks.iter().any(|c| c.status == CheckStatus::Error)
    }

    /// Return a copy whose `detail` strings omit filesystem paths, internal hostnames, and raw
    /// backend error strings so HTTP `/readyz` responses satisfy REST R5.17 (`R80`).
    #[must_use]
    pub fn redacted_for_http(&self) -> Self {
        let checks = self
            .checks
            .iter()
            .map(|c| {
                let detail = match (c.name, c.status) {
                    ("build", _) => c.detail.clone(),
                    ("config-file", CheckStatus::Ok) => "found".to_owned(),
                    ("config-file", CheckStatus::Warn) => "not found".to_owned(),
                    ("config-file", CheckStatus::Error) => "unavailable".to_owned(),
                    ("token", CheckStatus::Ok) => "present".to_owned(),
                    ("token", CheckStatus::Warn) => "not set".to_owned(),
                    ("token", CheckStatus::Error) => "unavailable".to_owned(),
                    ("readiness", CheckStatus::Error) => "service is draining".to_owned(),
                    (_, CheckStatus::Ok) => "ok".to_owned(),
                    (_, CheckStatus::Warn) => "warning".to_owned(),
                    (_, CheckStatus::Error) => "failed".to_owned(),
                };
                Check {
                    name: c.name,
                    status: c.status,
                    detail,
                }
            })
            .collect();
        Self { checks }
    }
}

/// Inputs inspected by [`run_diagnostics`].
#[derive(Debug, Clone, Copy)]
pub struct DiagnosticsContext<'a> {
    /// Active configuration file path to inspect for presence.
    pub config_path: &'a Path,
    /// Provenance label of the resolved credential, if a credential is present.
    pub token_source: Option<&'a str>,
    /// Sanitized error string if credential resolution failed.
    pub token_error: Option<&'a str>,
}

/// Collect shared local environment and readiness diagnostics (`R80`, `R03`, `R05`).
///
/// Synchronous and infallible: a failing check is data inside [`Diagnostics`], never an `Err`.
#[must_use]
pub fn run_diagnostics(ctx: &DiagnosticsContext<'_>) -> Diagnostics {
    let config_exists = ctx.config_path.exists();
    let config_check = Check {
        name: "config-file",
        status: if config_exists {
            CheckStatus::Ok
        } else {
            CheckStatus::Warn
        },
        detail: format!(
            "{} ({})",
            ctx.config_path.display(),
            if config_exists { "found" } else { "not found" }
        ),
    };

    let token_check = if let Some(err) = ctx.token_error {
        Check {
            name: "token",
            status: CheckStatus::Error,
            detail: err.to_owned(),
        }
    } else if let Some(source) = ctx.token_source {
        Check {
            name: "token",
            status: CheckStatus::Ok,
            detail: format!("present (source: {source})"),
        }
    } else {
        Check {
            name: "token",
            status: CheckStatus::Warn,
            detail: format!(
                "not set (supply via ${TOKEN_ENV_VAR} or a credential store; never stored in config)"
            ),
        }
    };

    let build_check = Check {
        name: "build",
        status: CheckStatus::Ok,
        detail: format!(
            "{VERSION} ({}/{})",
            std::env::consts::OS,
            std::env::consts::ARCH
        ),
    };

    Diagnostics {
        checks: vec![build_check, config_check, token_check],
    }
}

/// Build the single-check [`Diagnostics`] payload emitted by `/readyz` once the service has
/// entered graceful shutdown (`R80` AC6, AC9).
///
/// Defined here so all diagnostic check-name literals stay exclusively in `crates/core`.
#[must_use]
pub fn draining_diagnostics() -> Diagnostics {
    Diagnostics {
        checks: vec![Check {
            name: "readiness",
            status: CheckStatus::Error,
            detail: "service is draining".to_owned(),
        }],
    }
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use super::{Check, CheckStatus, Diagnostics, DiagnosticsContext, run_diagnostics};

    #[test]
    fn run_diagnostics_reports_warn_for_missing_config_and_token_and_redacts_paths() {
        let diag = run_diagnostics(&DiagnosticsContext {
            config_path: Path::new("/nonexistent-dir/secret-path/rslbp_config.toml"),
            token_source: None,
            token_error: None,
        });
        assert!(!diag.has_error());
        assert_eq!(diag.checks.len(), 3);
        assert_eq!(diag.checks[0].name, "build");
        assert_eq!(diag.checks[0].status, CheckStatus::Ok);
        assert_eq!(diag.checks[1].name, "config-file");
        assert_eq!(diag.checks[1].status, CheckStatus::Warn);
        assert!(diag.checks[1].detail.contains("secret-path"));
        assert_eq!(diag.checks[2].name, "token");
        assert_eq!(diag.checks[2].status, CheckStatus::Warn);

        let redacted = diag.redacted_for_http();
        assert!(!redacted.checks[1].detail.contains("secret-path"));
        assert_eq!(redacted.checks[1].detail, "not found");
        assert_eq!(redacted.checks[2].detail, "not set");
    }

    #[test]
    fn run_diagnostics_marks_token_error_and_redacts_detail() {
        let diag = run_diagnostics(&DiagnosticsContext {
            config_path: Path::new("/tmp"),
            token_source: None,
            token_error: Some("/etc/private/key permission denied"),
        });
        assert!(diag.has_error());
        let redacted = diag.redacted_for_http();
        assert!(redacted.has_error());
        assert!(!redacted.checks[2].detail.contains("/etc/private/key"));
        assert_eq!(redacted.checks[2].detail, "unavailable");

        let custom = Diagnostics {
            checks: vec![
                Check {
                    name: "readiness",
                    status: CheckStatus::Error,
                    detail: "draining".to_owned(),
                },
                Check {
                    name: "config-file",
                    status: CheckStatus::Error,
                    detail: "/secret".to_owned(),
                },
                Check {
                    name: "token",
                    status: CheckStatus::Ok,
                    detail: "env".to_owned(),
                },
                Check {
                    name: "custom",
                    status: CheckStatus::Ok,
                    detail: "internal".to_owned(),
                },
                Check {
                    name: "custom-warn",
                    status: CheckStatus::Warn,
                    detail: "internal".to_owned(),
                },
                Check {
                    name: "custom-err",
                    status: CheckStatus::Error,
                    detail: "internal".to_owned(),
                },
            ],
        };
        let red = custom.redacted_for_http();
        assert_eq!(red.checks[0].detail, "service is draining");
        assert_eq!(red.checks[1].detail, "unavailable");
        assert_eq!(red.checks[2].detail, "present");
        assert_eq!(red.checks[3].detail, "ok");
        assert_eq!(red.checks[4].detail, "warning");
        assert_eq!(red.checks[5].detail, "failed");
        assert_eq!(super::draining_diagnostics().checks[0].name, "readiness");
    }
}
