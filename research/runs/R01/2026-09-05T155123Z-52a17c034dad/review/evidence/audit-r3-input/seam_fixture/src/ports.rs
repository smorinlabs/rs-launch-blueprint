//! F001 — the port: a dyn-compatible Rust trait naming the driven-I/O capability.
//!
//! Rules kept so the trait can be erased to `Arc<dyn ProjectsPort>` at the composition root
//! (Rust Reference, "Dyn compatibility"): no generic methods, no associated consts, `Self` only in
//! receiver position, no `async fn` / opaque return types. `Send + Sync` supertraits let one erased
//! value be shared by a multi-threaded web layer; a single-threaded adapter is out of scope for the
//! template's shipped adapters (the alternative of bounding at the erasure site is recorded in DECISION.md).
//!
//! The error vocabulary (`PortError`) and the absence-versus-failure shape of `get` are placeholders:
//! R67 owns the error taxonomy and R03 owns the absence contract. The sync method shape is a fixture
//! choice, not R05's decision; under an async R05 the trait keeps dyn compatibility via `#[async_trait]`.

use std::sync::Arc;

use crate::contract::{Project, ProjectQuery};

/// Placeholder error vocabulary; R67/R03 decide the real one.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PortError {
    /// The adapter could not reach its backing store (transport failure, poisoned lock, ...).
    Unavailable(String),
    /// The backing store answered but its payload was not the shared contract.
    Decode(String),
}

impl std::fmt::Display for PortError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PortError::Unavailable(msg) => write!(f, "port unavailable: {msg}"),
            PortError::Decode(msg) => write!(f, "port payload not decodable: {msg}"),
        }
    }
}

impl std::error::Error for PortError {}

/// The driven-I/O port. Every adapter (production or fake) provides an explicit `impl`.
pub trait ProjectsPort: Send + Sync {
    /// Projects accepted by `query`, in the adapter's natural order.
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError>;

    /// The project with `id`, or `None` when absent (absence-vs-failure shape is R03's).
    fn get(&self, id: &str) -> Result<Option<Project>, PortError>;
}

/// Blanket impl: an `Arc<dyn ProjectsPort>` (or `Arc<Concrete>`) is itself a `ProjectsPort`, so one
/// generic `ProjectsService<P>` serves both static and erased dispatch.
impl<T: ProjectsPort + ?Sized> ProjectsPort for Arc<T> {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        (**self).list(query)
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        (**self).get(id)
    }
}
