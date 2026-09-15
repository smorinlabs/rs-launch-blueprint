//! F002 — the composition root: two plain functions, no dependency-injection container.
//!
//! `build_projects_service` is for callers that bring their own adapter (tests, the in-memory demo);
//! `production_service` is the only place in the crate that constructs the production adapter.

use std::sync::Arc;

use crate::adapters::http::HttpProjectsPort;
use crate::ports::ProjectsPort;
use crate::service::{ErasedProjectsService, ProjectsService};

pub fn build_projects_service(port: Arc<dyn ProjectsPort>) -> ErasedProjectsService {
    ProjectsService::new(port)
}

/// Wire the production adapter. `authority` is `host:port` of the upstream projects API.
pub fn production_service(authority: &str) -> ErasedProjectsService {
    build_projects_service(Arc::new(HttpProjectsPort::new(authority)))
}
