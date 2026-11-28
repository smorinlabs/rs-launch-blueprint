//! Core package metadata and workspace descriptor types.

/// Crate name of the core library package.
pub const CORE_NAME: &str = env!("CARGO_PKG_NAME");

/// Workspace-inherited package version shared across core, library, CLI, and optional web crates
/// (`R22`, `R80`).
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Static package identity returned by the standalone library facade.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WorkspaceInfo {
    /// Library package name (`rs-launch-blueprint`).
    pub package: &'static str,
    /// Package version from `Cargo.toml` (`R22`).
    pub version: &'static str,
}

impl WorkspaceInfo {
    /// Construct a new [`WorkspaceInfo`] descriptor.
    #[must_use]
    pub const fn new(package: &'static str, version: &'static str) -> Self {
        Self { package, version }
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
        let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0");
        assert_eq!(info.package, "rs-launch-blueprint");
        assert_eq!(info.version, "0.1.0");
        assert_eq!(CORE_NAME, "rs-launch-blueprint-core");
        assert_eq!(INTERNAL_TAG, "core-internal");
    }
}
