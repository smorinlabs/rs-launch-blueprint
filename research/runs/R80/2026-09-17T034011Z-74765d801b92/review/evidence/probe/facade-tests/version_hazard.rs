// R80 probe workspace — check A / check B. The assertion is deliberately written
// against the two version strings the manifests supply, so the same test file
// FAILS in variant A's shape if inheritance were silently in effect and passes
// in variant B only when both packages report the workspace version.
#[test]
fn version_hazard() {
    let facade = facade::FACADE_PKG_VERSION;
    let web_member = probe_web::WEB_PKG_VERSION;
    let core_member = probe_core::VERSION;
    println!("facade_env_CARGO_PKG_VERSION={facade}");
    println!("web_member_env_CARGO_PKG_VERSION={web_member}");
    println!("core_member_env_CARGO_PKG_VERSION={core_member}");
    println!("std_env_consts_OS={}", std::env::consts::OS);
    println!("std_env_consts_ARCH={}", std::env::consts::ARCH);
    let _static_os: &'static str = std::env::consts::OS;
    let _static_arch: &'static str = std::env::consts::ARCH;
    println!("os_and_arch_are_static_str=true");

    let expected_facade = "0.4.2";
    let expected_member = std::env::var("R80_EXPECTED_MEMBER_VERSION")
        .expect("R80_EXPECTED_MEMBER_VERSION must be set by the check script");
    assert_eq!(facade, expected_facade, "facade version");
    assert_eq!(web_member, expected_member, "web member version");
    assert_eq!(core_member, expected_member, "core member version");
}
