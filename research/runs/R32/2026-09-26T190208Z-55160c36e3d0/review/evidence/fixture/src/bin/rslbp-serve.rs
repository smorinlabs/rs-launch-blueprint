use std::process::ExitCode;

fn main() -> ExitCode {
    println!("health={}", rs_launch_blueprint::web::health());
    ExitCode::SUCCESS
}
