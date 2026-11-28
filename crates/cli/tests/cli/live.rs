//! Opt-in live test class (`R32` M5 / F130).

use std::time::Duration;

use assert_cmd::cargo::cargo_bin_cmd;

use crate::support::{StubHttpServer, StubResponse};

#[test]
#[ignore = "live: end-to-end TCP round-trip against loopback or configured RSLBP_LIVE_API_URL"]
fn live_tcp_projects_list_round_trip() {
    let server = StubHttpServer::start(|_| {
        StubResponse::ok_json(r#"{"data":[{"gid":"live-1","name":"Live Demo","workspace":null}]}"#)
    });
    let base_url = std::env::var("RSLBP_LIVE_API_URL").unwrap_or_else(|_| server.base_url());
    let token = std::env::var("RSLBP_LIVE_TOKEN").unwrap_or_else(|_| "sk_live_loopback".to_owned());

    cargo_bin_cmd!("rslbp")
        .args(["project", "list", "--json"])
        .env("RSLBP_API_BASE_URL", base_url)
        .env("RSLBP_TOKEN", token)
        .timeout(Duration::from_secs(10))
        .assert()
        .success();
}
