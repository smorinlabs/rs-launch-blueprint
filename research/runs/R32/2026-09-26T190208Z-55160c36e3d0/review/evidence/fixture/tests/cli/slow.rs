#[test]
#[ignore = "slow: takes >1s"]
fn large_config_round_trip() {
    std::thread::sleep(std::time::Duration::from_millis(1200));
}
