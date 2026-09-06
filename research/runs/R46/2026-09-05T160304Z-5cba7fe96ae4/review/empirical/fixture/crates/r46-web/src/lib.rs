//! R46 fixture web-service member.
//!
//! Module documentation comes first; the license is inherited from
//! `[workspace.package]`, and no HTTP framework is linked so the fixture stays
//! dependency-free.

/// A stand-in request handler.
pub fn handle(path: &str) -> (u16, &'static str) {
    match path {
        "/health" => (200, "ok"),
        _ => (404, "not found"),
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn member_inherits_the_workspace_license() {
        assert_eq!(env!("CARGO_PKG_LICENSE"), "MIT OR Apache-2.0");
    }

    #[test]
    fn health_route_answers_200() {
        assert_eq!(super::handle("/health"), (200, "ok"));
    }
}
