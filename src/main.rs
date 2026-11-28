//! CLI binary entrypoint (`rslbp`) for `rs-launch-blueprint`.

use std::env;
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    rs_launch_blueprint::run_cli(&args)
}
