//! The CLI front end: builds `ProjectQuery` from arguments, calls the same erased service the web
//! layer uses, and renders the same `Project` values as JSON. No adapter is constructed here except
//! through the composition root.
//!
//! Usage: `seam-cli [--upstream host:port | --in-memory] [needle]`

use std::process::ExitCode;
use std::sync::Arc;

use seam_fixture::{
    InMemoryProjectsPort, ProjectQuery, build_projects_service, production_service, testing,
};

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut upstream: Option<String> = None;
    let mut in_memory = false;
    let mut needle: Option<String> = None;
    let mut iter = args.into_iter();
    while let Some(arg) = iter.next() {
        match arg.as_str() {
            "--upstream" => upstream = iter.next(),
            "--in-memory" => in_memory = true,
            other => needle = Some(other.to_string()),
        }
    }

    let service = match (upstream, in_memory) {
        (Some(authority), _) => production_service(&authority),
        (None, true) => build_projects_service(Arc::new(InMemoryProjectsPort::seeded(
            testing::sample_rows(),
        ))),
        (None, false) => {
            eprintln!("usage: seam-cli [--upstream host:port | --in-memory] [needle]");
            return ExitCode::from(2);
        }
    };

    let query = match needle {
        Some(n) => ProjectQuery::matching(n),
        None => ProjectQuery::default(),
    };
    match service.search(&query) {
        Ok(rows) => {
            println!(
                "{}",
                serde_json::to_string_pretty(&rows).expect("contract serializes")
            );
            ExitCode::SUCCESS
        }
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}
