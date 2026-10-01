use assert_cmd::cargo::cargo_bin_cmd;
use predicates::str::contains;
use std::time::Duration;

#[test]
fn binary_lists_projects() {
    cargo_bin_cmd!("rslbp")
        .arg("projects")
        .env("RSLBP_FAKE_PROJECTS", "Alpha,Beta")
        .timeout(Duration::from_secs(10))
        .assert()
        .success()
        .stdout("Alpha\nBeta\n");
}

#[test]
fn binary_usage_error_exits_2_with_empty_stdout() {
    cargo_bin_cmd!("rslbp")
        .arg("nope")
        .timeout(Duration::from_secs(10))
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB201"));
}
