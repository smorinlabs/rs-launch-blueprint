//! Private internal details excluded from the root public-API barrel (`R04`).

/// Internal marker type that must never be nameable outside `rs_launch_blueprint`.
#[cfg_attr(
    not(test),
    expect(dead_code, reason = "fixture for R04 compile_fail privacy doctest")
)]
pub(crate) struct InternalMarker;

#[cfg(test)]
mod tests {
    use super::InternalMarker;

    #[test]
    fn internal_marker_is_zero_sized() {
        let _marker = InternalMarker;
        assert_eq!(std::mem::size_of::<InternalMarker>(), 0);
    }
}
