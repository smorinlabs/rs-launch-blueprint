use std::process::ExitCode;

fn main() -> ExitCode {
    let code = rs_launch_blueprint::run(
        std::env::args(),
        &rs_launch_blueprint::EnvProjectsPort,
        &mut std::io::stdout().lock(),
        &mut std::io::stderr().lock(),
    );
    ExitCode::from(code)
}
