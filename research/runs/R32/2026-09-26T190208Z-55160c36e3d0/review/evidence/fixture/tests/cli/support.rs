use rs_launch_blueprint::{run, InMemoryProjectsPort};

/// Local factory helper: an in-memory port holding `names`.
pub fn fake(names: &[&str]) -> InMemoryProjectsPort {
    InMemoryProjectsPort(names.iter().map(|s| (*s).to_owned()).collect())
}

/// Runs the CLI in-process and captures (exit code, stdout, stderr).
pub fn run_captured(args: &[&str], port: &InMemoryProjectsPort) -> (u8, String, String) {
    let (mut out, mut err) = (Vec::new(), Vec::new());
    let code = run(args, port, &mut out, &mut err);
    (code, String::from_utf8(out).unwrap(), String::from_utf8(err).unwrap())
}
