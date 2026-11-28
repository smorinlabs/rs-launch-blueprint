//! CLI front-end crate for `rs-launch-blueprint`.
//!
//! Depends strictly on `rs-launch-blueprint-core` (`R02`).
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_cli::app::run;
//! let _ = run;
//! ```

mod app;

pub use app::run;
