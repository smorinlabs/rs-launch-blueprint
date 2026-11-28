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

mod composition;
mod internal;

/// The version of this package, from `Cargo.toml` (`R22`).
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(feature = "web")]
pub use composition::run_web_stub;
pub use composition::{run_cli, workspace_info};
pub use rs_launch_blueprint_core::WorkspaceInfo;
