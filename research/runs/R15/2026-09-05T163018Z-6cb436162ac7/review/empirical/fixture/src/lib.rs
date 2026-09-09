//! Library surface of the fixture. The crate is named in `tests/cli.rs`
//! (`use rs_launch_blueprint::run`) so the underscored identity occurs in
//! tracked content, which `press verify` requires for an undiscoverable field.

/// Directory environment variable the CLI honours (glued SCREAMING form).
pub const RSLBP_HOME: &str = "RSLBP_HOME";

/// Returns the greeting the binary prints; identity comes from Cargo, not a literal.
pub fn run() -> String {
    format!("hello from {}", env!("CARGO_PKG_NAME"))
}
