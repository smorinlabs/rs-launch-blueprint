//! Dependency-free build script recording compile target and rustc version (`R60` F267).

use std::env;
use std::process::Command;

fn main() {
    println!("cargo::rerun-if-env-changed=TARGET");
    println!("cargo::rerun-if-env-changed=RUSTC");

    let target = env::var("TARGET").unwrap_or_else(|_| "unknown".to_owned());
    println!("cargo::rustc-env=RSLBP_BUILD_TARGET={target}");

    let rustc = env::var_os("RUSTC").unwrap_or_else(|| "rustc".into());
    let rustc_version = Command::new(rustc)
        .arg("-vV")
        .output()
        .ok()
        .filter(|out| out.status.success())
        .and_then(|out| String::from_utf8(out.stdout).ok())
        .and_then(|stdout| {
            stdout
                .lines()
                .find_map(|line| line.strip_prefix("release: ").map(str::trim))
                .or_else(|| stdout.lines().next().map(str::trim))
                .map(str::to_owned)
        })
        .unwrap_or_else(|| "unknown".to_owned());

    println!("cargo::rustc-env=RSLBP_BUILD_RUSTC={rustc_version}");
}
