//! R46 fixture library crate.
//!
//! Crate-level documentation is the first element of the file. The license is
//! declared once, in `Cargo.toml`, and shipped as the root `LICENSE-APACHE`
//! and `LICENSE-MIT` files; no source file repeats it.

/// Returns the license expression Cargo resolved for this package.
pub fn license_expression() -> &'static str {
    env!("CARGO_PKG_LICENSE")
}

#[cfg(test)]
mod tests {
    #[test]
    fn package_license_is_the_fixed_dual_expression() {
        assert_eq!(super::license_expression(), "MIT OR Apache-2.0");
    }
}
