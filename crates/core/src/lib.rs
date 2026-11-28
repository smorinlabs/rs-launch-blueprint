//! Core library crate for `rs-launch-blueprint`.
//!
//! All internal modules are private and re-exported through the curated root surface (`R04`).
//!
//! ```
//! use rs_launch_blueprint_core::{CORE_NAME, WorkspaceInfo};
//!
//! let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", false);
//! assert_eq!(CORE_NAME, "rs-launch-blueprint-core");
//! assert_eq!(info.package, "rs-launch-blueprint");
//! ```
//!
//! Internal modules cannot be imported directly by external consumers:
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_core::metadata::WorkspaceInfo;
//! let _ = WorkspaceInfo::new("a", "0.1.0", false);
//! ```

mod metadata;

pub use metadata::{CORE_NAME, WorkspaceInfo};
