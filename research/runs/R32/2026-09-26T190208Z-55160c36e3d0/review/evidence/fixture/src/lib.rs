//! Stand-in library for the R32 harness fixture.
use std::io::Write;

/// Driven-I/O port in R01's shape: dyn-compatible, `Send + Sync`.
pub trait ProjectsPort: Send + Sync {
    fn list(&self) -> Result<Vec<String>, String>;
}

impl<T: ProjectsPort + ?Sized> ProjectsPort for std::sync::Arc<T> {
    fn list(&self) -> Result<Vec<String>, String> {
        (**self).list()
    }
}

/// The shipped in-memory fake that tests inject.
pub struct InMemoryProjectsPort(pub Vec<String>);

impl ProjectsPort for InMemoryProjectsPort {
    fn list(&self) -> Result<Vec<String>, String> {
        Ok(self.0.clone())
    }
}

/// Stand-in production adapter; the real one is an HTTP client (R01, R48).
pub struct EnvProjectsPort;

impl ProjectsPort for EnvProjectsPort {
    fn list(&self) -> Result<Vec<String>, String> {
        let raw = std::env::var("RSLBP_FAKE_PROJECTS").map_err(|e| e.to_string())?;
        Ok(raw.split(',').filter(|s| !s.is_empty()).map(str::to_owned).collect())
    }
}

/// Runs the CLI against `port`, writing to `out` and `err`; returns the exit code.
///
/// ```
/// use rs_launch_blueprint::{run, InMemoryProjectsPort};
/// let (mut out, mut err) = (Vec::new(), Vec::new());
/// let port = InMemoryProjectsPort(vec!["Alpha".into()]);
/// assert_eq!(run(["rslbp", "projects"], &port, &mut out, &mut err), 0);
/// assert_eq!(out, b"Alpha\n");
/// ```
pub fn run<I, S>(args: I, port: &dyn ProjectsPort, out: &mut dyn Write, err: &mut dyn Write) -> u8
where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
{
    let args: Vec<String> = args.into_iter().map(|a| a.as_ref().to_owned()).collect();
    match args.get(1).map(String::as_str) {
        Some("projects") => match port.list() {
            Ok(names) => {
                for n in names {
                    let _ = writeln!(out, "{n}");
                }
                0
            }
            Err(e) => {
                let _ = writeln!(err, "{{\"error\":{{\"code\":\"RSLB103\",\"message\":\"{e}\"}}}}");
                1
            }
        },
        _ => {
            let _ = writeln!(err, "{{\"error\":{{\"code\":\"RSLB201\",\"message\":\"unknown command\"}}}}");
            2
        }
    }
}

/// Stand-in for R69's feature-gated `src/web/` module.
#[cfg(feature = "web")]
pub mod web {
    /// Liveness body.
    pub fn health() -> &'static str {
        "ok"
    }
}
