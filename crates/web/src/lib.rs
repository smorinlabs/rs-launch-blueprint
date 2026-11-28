//! Optional web service front-end crate for `rs-launch-blueprint`.
//!
//! Enabled via the root package's off-by-default `web` feature (`R69`, `R02`).
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_web::server::serve_stub;
//! let _ = serve_stub;
//! ```

mod server;

pub use server::serve_stub;
