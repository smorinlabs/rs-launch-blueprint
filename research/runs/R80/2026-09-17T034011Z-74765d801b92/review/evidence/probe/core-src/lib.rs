// R80 probe workspace — the shared diagnostics contract, as it would sit in
// `crates/core/src/diagnostics.rs`. Synchronous (R05 revision 3), infallible
// (R03 revision 1), no framework type (R02 revision 2). The only external
// dependency is `serde`.
//
// This file is a PROBE, not the recommendation's final signature: the real
// `run_diagnostics` takes the template's `&Config` (a type no published item has
// defined yet), so the probe takes the two inputs a `Config` would carry.

use std::path::Path;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "lowercase")]
pub enum CheckStatus {
    Ok,
    Warn,
    Error,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct Check {
    pub name: &'static str,
    pub status: CheckStatus,
    pub detail: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct Diagnostics {
    pub checks: Vec<Check>,
}

impl Diagnostics {
    pub fn has_error(&self) -> bool {
        self.checks.iter().any(|c| c.status == CheckStatus::Error)
    }
}

/// The one function the CLI `doctor` command and the web `/readyz` handler both
/// call. Ports py's check set minus `python`, which has no Rust analogue.
pub fn run_diagnostics(config_path: &Path, has_credential: bool) -> Diagnostics {
    let mut checks = Vec::new();

    checks.push(Check {
        name: "build",
        status: CheckStatus::Ok,
        detail: format!(
            "{} on {}/{}",
            VERSION,
            std::env::consts::OS,
            std::env::consts::ARCH
        ),
    });

    let (config_status, config_detail) = if config_path.exists() {
        (CheckStatus::Ok, format!("found at {}", config_path.display()))
    } else {
        (
            CheckStatus::Warn,
            format!("no config file at {}", config_path.display()),
        )
    };
    checks.push(Check {
        name: "config-file",
        status: config_status,
        detail: config_detail,
    });

    checks.push(Check {
        name: "credential",
        status: if has_credential {
            CheckStatus::Ok
        } else {
            CheckStatus::Warn
        },
        detail: if has_credential {
            "credential present".to_string()
        } else {
            "no credential configured".to_string()
        },
    });

    Diagnostics { checks }
}
