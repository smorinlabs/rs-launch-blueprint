//! Opt-in slow test class (`R32` M5 / F130).

use std::time::Duration;

use assert_cmd::cargo::cargo_bin_cmd;

#[test]
#[ignore = "slow: repeated built-binary invocations exercising CLI startup stability"]
fn slow_repeated_version_invocations_are_consistent() {
    let expected = format!("rslbp {}\n", rs_launch_blueprint::VERSION);
    for _ in 0..5 {
        cargo_bin_cmd!("rslbp")
            .arg("--version")
            .timeout(Duration::from_secs(10))
            .assert()
            .success()
            .stdout(expected.clone());
    }
}
