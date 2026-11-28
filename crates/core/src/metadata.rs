//! Core package metadata and workspace descriptor types.

/// Crate name of the core library package.
pub const CORE_NAME: &str = env!("CARGO_PKG_NAME");

/// Workspace-inherited package version shared across core, CLI, and optional web crates (`R22`,
/// `R80`).
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Static workspace identity returned by the facade composition root.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WorkspaceInfo {
    /// Root package name (`rs-launch-blueprint`).
    pub package: &'static str,
    /// Package version from `Cargo.toml` (`R22`).
    pub version: &'static str,
    /// Whether the optional `web` feature was enabled at compile time.
    pub web_enabled: bool,
}

impl WorkspaceInfo {
    /// Construct a new [`WorkspaceInfo`] descriptor.
    #[must_use]
    pub const fn new(package: &'static str, version: &'static str, web_enabled: bool) -> Self {
        Self {
            package,
            version,
            web_enabled,
        }
    }
}

/// Internal helper kept crate-private to exercise module privacy boundaries.
#[cfg_attr(
    not(test),
    expect(dead_code, reason = "retained for unit and privacy-boundary checks")
)]
pub(crate) const INTERNAL_TAG: &str = "core-internal";

#[cfg(test)]
mod tests {
    use super::{CORE_NAME, INTERNAL_TAG, WorkspaceInfo};

    #[test]
    fn workspace_info_preserves_fields() {
        let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", false);
        assert_eq!(info.package, "rs-launch-blueprint");
        assert_eq!(info.version, "0.1.0");
        assert!(!info.web_enabled);
        assert_eq!(CORE_NAME, "rs-launch-blueprint-core");
        assert_eq!(INTERNAL_TAG, "core-internal");
    }
}
