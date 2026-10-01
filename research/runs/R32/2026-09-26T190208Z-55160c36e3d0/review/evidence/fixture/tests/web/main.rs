//! Web tier: compiled only with the `web` feature (R69's file-level gate).
#![cfg(feature = "web")]

use assert_cmd::cargo::cargo_bin_cmd;

#[test]
fn health_is_ok_in_process() {
    assert_eq!(rs_launch_blueprint::web::health(), "ok");
}

#[test]
fn serve_binary_starts() {
    cargo_bin_cmd!("rslbp-serve")
        .timeout(std::time::Duration::from_secs(10))
        .assert()
        .success()
        .stdout("health=ok\n");
}
