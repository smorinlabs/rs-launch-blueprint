use rs_launch_blueprint::run;

#[test]
fn library_greets_with_cargo_package_name() {
    assert_eq!(run(), format!("hello from {}", env!("CARGO_PKG_NAME")));
}

#[test]
fn binary_target_exists_under_the_declared_app_name() {
    // `CARGO_BIN_EXE_<name>` is set by Cargo for integration tests; a renamed
    // or missing bin target makes this fail to compile.
    let exe = env!("CARGO_BIN_EXE_rslbp");
    let out = std::process::Command::new(exe).output().expect("run the binary");
    assert!(out.status.success());
}
