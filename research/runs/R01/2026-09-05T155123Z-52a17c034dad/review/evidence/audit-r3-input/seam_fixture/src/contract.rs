//! F018 — the one data contract both front ends use.
//!
//! The CLI renders these types; the web adapter deserializes `ProjectQuery` from the query string and
//! serializes `Project` into the response body. Neither front end declares a mirror struct.
//! The concrete wire format and the error envelope are R66's and R70's decisions; this module only
//! establishes that both front ends name the same type.

use serde::{Deserialize, Serialize};

/// A project record as the port returns it and as the CLI and the web layer emit it.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Project {
    pub id: String,
    pub name: String,
}

/// The shared request shape: the CLI builds it from arguments, the web adapter from the query string.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProjectQuery {
    /// Case-sensitive substring match on `Project::name`; `None` lists every project.
    #[serde(default)]
    pub q: Option<String>,
}

impl ProjectQuery {
    pub fn matching(q: impl Into<String>) -> Self {
        Self { q: Some(q.into()) }
    }

    pub fn accepts(&self, project: &Project) -> bool {
        match &self.q {
            Some(needle) => project.name.contains(needle.as_str()),
            None => true,
        }
    }
}
