//! Shared domain models (`R01` F018).
//!
//! Serialized directly by both the CLI and the optional web service so neither front end
//! maintains a duplicate mirror struct.

use std::num::NonZeroU32;

use serde::{Deserialize, Serialize};

/// Default maximum number of projects returned when [`ProjectQuery::limit`] is `None`.
pub const DEFAULT_PROJECT_LIMIT: u32 = 200;

/// A single project returned by a [`crate::ProjectsPort`] implementation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Project {
    /// Unique identifier assigned by the backing store.
    pub id: String,
    /// Human-readable project name.
    pub name: String,
    /// Optional workspace name owning this project.
    pub workspace: Option<String>,
}

/// Filter and pagination parameters for listing projects.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct ProjectQuery {
    /// Optional workspace name filter.
    pub workspace: Option<String>,
    /// Optional positive result cap; falls back to [`DEFAULT_PROJECT_LIMIT`] when `None`.
    pub limit: Option<NonZeroU32>,
}

impl ProjectQuery {
    /// Return the configured limit or [`DEFAULT_PROJECT_LIMIT`].
    #[must_use]
    pub const fn limit_or_default(&self) -> u32 {
        match self.limit {
            Some(n) => n.get(),
            None => DEFAULT_PROJECT_LIMIT,
        }
    }
}

/// Input payload for creating a new project.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CreateProjectInput {
    /// Non-empty human-readable project name.
    pub name: String,
    /// Optional workspace name.
    pub workspace: Option<String>,
}
