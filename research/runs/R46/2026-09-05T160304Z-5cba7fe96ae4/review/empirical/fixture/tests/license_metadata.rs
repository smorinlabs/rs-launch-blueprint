//! Integration test target: the dual expression is visible to dependents.

#[test]
fn integration_target_sees_the_dual_license() {
    assert_eq!(r46_fixture::license_expression(), "MIT OR Apache-2.0");
}
