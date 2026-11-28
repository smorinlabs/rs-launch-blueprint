//! Optional web service binary entrypoint (`rslbp-serve`, requires `web` feature).

#![deny(clippy::print_stdout, clippy::print_stderr)]

use std::env;
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    rs_launch_blueprint::run_web_stub(&args)
}
