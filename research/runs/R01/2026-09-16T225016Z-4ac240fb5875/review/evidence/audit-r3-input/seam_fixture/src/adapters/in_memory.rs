//! F013 — the shipped first-class fake: public, unconditional (no `cfg(test)`), standard library only.
//!
//! The port takes `&self`, so a stateful fake needs interior mutability; `std::sync::Mutex` gives it
//! behind `&self` while keeping the type `Send + Sync`, which the erased web state requires.
//! A poisoned lock is reported through the port's own error vocabulary instead of panicking.

use std::sync::Mutex;

use crate::contract::{Project, ProjectQuery};
use crate::ports::{PortError, ProjectsPort};

#[derive(Debug, Default)]
pub struct InMemoryProjectsPort {
    rows: Mutex<Vec<Project>>,
}

impl InMemoryProjectsPort {
    pub fn seeded(rows: Vec<Project>) -> Self {
        Self {
            rows: Mutex::new(rows),
        }
    }

    /// Test-visible mutation so a suite can change state between calls.
    pub fn insert(&self, project: Project) -> Result<(), PortError> {
        self.rows
            .lock()
            .map_err(|e| PortError::Unavailable(format!("in-memory rows poisoned: {e}")))?
            .push(project);
        Ok(())
    }
}

impl ProjectsPort for InMemoryProjectsPort {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        let rows = self
            .rows
            .lock()
            .map_err(|e| PortError::Unavailable(format!("in-memory rows poisoned: {e}")))?;
        Ok(rows.iter().filter(|p| query.accepts(p)).cloned().collect())
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        let rows = self
            .rows
            .lock()
            .map_err(|e| PortError::Unavailable(format!("in-memory rows poisoned: {e}")))?;
        Ok(rows.iter().find(|p| p.id == id).cloned())
    }
}
