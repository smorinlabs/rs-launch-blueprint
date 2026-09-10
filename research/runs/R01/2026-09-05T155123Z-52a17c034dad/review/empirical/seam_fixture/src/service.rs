//! The use case, generic over the port. Library consumers instantiate `ProjectsService<Concrete>`
//! (static dispatch, monomorphized); the CLI and the web layer share the one erased instantiation
//! `ProjectsService<Arc<dyn ProjectsPort>>`, which is `Clone + Send + Sync + 'static`.

use std::sync::Arc;

use crate::contract::{Project, ProjectQuery};
use crate::ports::{PortError, ProjectsPort};

#[derive(Debug, Clone)]
pub struct ProjectsService<P: ProjectsPort> {
    port: P,
}

/// The single instantiation the CLI and the web adapter name.
pub type ErasedProjectsService = ProjectsService<Arc<dyn ProjectsPort>>;

impl<P: ProjectsPort> ProjectsService<P> {
    pub fn new(port: P) -> Self {
        Self { port }
    }

    /// Use-case behavior the adapters do not own: results are returned sorted by `id`.
    pub fn search(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        let mut rows = self.port.list(query)?;
        rows.sort_by(|a, b| a.id.cmp(&b.id));
        Ok(rows)
    }

    pub fn find(&self, id: &str) -> Result<Option<Project>, PortError> {
        self.port.get(id)
    }
}
