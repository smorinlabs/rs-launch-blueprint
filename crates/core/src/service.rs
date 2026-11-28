//! Application use-case layer over [`ProjectsPort`] (`R01`, `R03`).
//!
//! This is the sole translation site converting port absence (`Ok(None)` / `Ok(false)`) into
//! [`DomainError::NotFound`] (`RSLB301`).

use std::sync::Arc;

use crate::error::DomainError;
use crate::models::{CreateProjectInput, Project, ProjectQuery};
use crate::ports::ProjectsPort;

/// Transport-neutral application service orchestrating a [`ProjectsPort`] (`R01`).
///
/// Generic for zero-overhead library callers; erased at the composition root via
/// [`ErasedProjectsService`].
#[derive(Debug)]
pub struct ProjectsService<P: ProjectsPort> {
    port: P,
}

impl<P: ProjectsPort + Clone> Clone for ProjectsService<P> {
    fn clone(&self) -> Self {
        Self {
            port: self.port.clone(),
        }
    }
}

/// Erased service instantiation shared by the CLI and optional web front ends (`R01`).
pub type ErasedProjectsService = ProjectsService<Arc<dyn ProjectsPort>>;

impl<P: ProjectsPort> ProjectsService<P> {
    /// Construct a new [`ProjectsService`] backed by `port`.
    #[must_use]
    pub const fn new(port: P) -> Self {
        Self { port }
    }

    /// Borrow the underlying port implementation.
    #[must_use]
    pub const fn port(&self) -> &P {
        &self.port
    }

    /// List projects matching `query`. An empty result is `Ok(vec![])`, never `NotFound`.
    pub fn list_projects(&self, query: &ProjectQuery) -> Result<Vec<Project>, DomainError> {
        tracing::debug!(
            workspace = query.workspace.as_deref().unwrap_or("*"),
            limit = query.limit_or_default(),
            "listing projects"
        );
        Ok(self.port.list(query)?)
    }

    /// Fetch a project by identity, translating `Ok(None)` into [`DomainError::NotFound`].
    ///
    /// Forgetting the absence translation is a compile error (`R03` AC7):
    ///
    /// ```compile_fail,E0308
    /// use rs_launch_blueprint_core::{DomainError, Project, ProjectsPort};
    ///
    /// fn broken(port: &dyn ProjectsPort, id: &str) -> Result<Project, DomainError> {
    ///     Ok(port.get(id)?)
    /// }
    /// ```
    pub fn get_project(&self, id: &str) -> Result<Project, DomainError> {
        tracing::debug!(project_id = id, "fetching project");
        self.port.get(id)?.ok_or_else(|| DomainError::NotFound {
            kind: "project",
            id: id.to_owned(),
        })
    }

    /// Fetch a project by identity, preserving `Ok(None)` for callers that treat absence as normal.
    pub fn find_project(&self, id: &str) -> Result<Option<Project>, DomainError> {
        tracing::debug!(project_id = id, "looking up optional project");
        Ok(self.port.get(id)?)
    }

    /// Validate input and create a new project.
    pub fn create_project(&self, input: &CreateProjectInput) -> Result<Project, DomainError> {
        let trimmed = input.name.trim();
        if trimmed.is_empty() {
            return Err(DomainError::Usage {
                message: "project name must not be empty".to_owned(),
                hint: Some("provide a non-empty project name".to_owned()),
            });
        }
        let normalized = CreateProjectInput {
            name: trimmed.to_owned(),
            workspace: input
                .workspace
                .as_deref()
                .map(str::trim)
                .filter(|s| !s.is_empty())
                .map(str::to_owned),
        };
        tracing::debug!(
            name = normalized.name.as_str(),
            workspace = normalized.workspace.as_deref().unwrap_or("-"),
            "creating project"
        );
        Ok(self.port.create(&normalized)?)
    }

    /// Delete a project by identity, translating absence into [`DomainError::NotFound`].
    pub fn delete_project(&self, id: &str) -> Result<(), DomainError> {
        tracing::debug!(project_id = id, "deleting project");
        if self.port.delete(id)? {
            Ok(())
        } else {
            Err(DomainError::NotFound {
                kind: "project",
                id: id.to_owned(),
            })
        }
    }

    /// Delete a project if it exists, returning `Ok(false)` when already absent (`R03`).
    pub fn delete_project_if_exists(&self, id: &str) -> Result<bool, DomainError> {
        tracing::debug!(project_id = id, "deleting project if exists");
        Ok(self.port.delete(id)?)
    }
}
