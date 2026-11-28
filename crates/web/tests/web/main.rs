//! Web integration-test tier (`R32` F129, `R69` revision 11).
//!
//! Lives in `crates/web/tests/web/main.rs` with no file-level `#![cfg(feature = "web")]`
//! because `rs-launch-blueprint-web` is an optional workspace member.

use std::process::ExitCode;

use rs_launch_blueprint_core::WorkspaceInfo;
use rs_launch_blueprint_web::serve_stub;

#[test]
fn web_tier_serve_stub_handles_version_help_and_unknown_flag() {
    let info = WorkspaceInfo::new("rs-launch-blueprint", "0.1.0", true);
    assert_eq!(
        serve_stub(info, &["--version".to_owned()]),
        ExitCode::SUCCESS
    );
    assert_eq!(serve_stub(info, &["--help".to_owned()]), ExitCode::SUCCESS);
    assert_eq!(serve_stub(info, &[]), ExitCode::SUCCESS);
    assert_eq!(serve_stub(info, &["--nope".to_owned()]), ExitCode::from(2));
}
