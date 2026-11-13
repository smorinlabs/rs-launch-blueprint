//! R01 empirical fixture — the ports-and-adapters seam end to end for one port.
//!
//! Layout (the crate placement of each module is R02's decision; this fixture is one crate):
//!
//! - [`contract`]   — the shared data contract (`Project`, `ProjectQuery`) with `serde` derives (F018).
//! - [`ports`]      — the dyn-compatible port trait `ProjectsPort` and the blanket `Arc<T>` impl (F001).
//! - [`adapters`]   — the shipped in-memory fake (F013) and an HTTP adapter used as the "real" one.
//! - [`service`]    — `ProjectsService<P: ProjectsPort>` and the erased alias the CLI and web share.
//! - [`composition`]— the plain-function composition root; the only place the production adapter is built (F002).
//! - [`testing`]    — the generic contract suite run once per adapter (F121).
//! - [`web`]        — the thin web adapter over the same service and the same data contract (F018).
//!
//! # F011 — an adapter that omits a port method fails `cargo check`, not a test
//!
//! Positive twin (identical imports, complete impl) — compiles:
//!
//! ```
//! use seam_fixture::contract::{Project, ProjectQuery};
//! use seam_fixture::ports::{PortError, ProjectsPort};
//! struct Complete;
//! impl ProjectsPort for Complete {
//!     fn list(&self, _q: &ProjectQuery) -> Result<Vec<Project>, PortError> { Ok(vec![]) }
//!     fn get(&self, _id: &str) -> Result<Option<Project>, PortError> { Ok(None) }
//! }
//! let _: std::sync::Arc<dyn ProjectsPort> = std::sync::Arc::new(Complete);
//! ```
//!
//! Negative twin — the same impl with `get` omitted is rejected by rustc (E0046, not all trait items implemented):
//!
//! ```compile_fail
//! use seam_fixture::contract::{Project, ProjectQuery};
//! use seam_fixture::ports::{PortError, ProjectsPort};
//! struct Incomplete;
//! impl ProjectsPort for Incomplete {
//!     fn list(&self, _q: &ProjectQuery) -> Result<Vec<Project>, PortError> { Ok(vec![]) }
//! }
//! let _: std::sync::Arc<dyn ProjectsPort> = std::sync::Arc::new(Incomplete);
//! ```
//!
//! # Dyn compatibility is a compiler-enforced property of the port
//!
//! Positive twin — a port with only dispatchable methods can be erased:
//!
//! ```
//! trait DynOk: Send + Sync { fn name(&self) -> String; }
//! struct A;
//! impl DynOk for A { fn name(&self) -> String { "a".into() } }
//! let erased: std::sync::Arc<dyn DynOk> = std::sync::Arc::new(A);
//! assert_eq!(erased.name(), "a");
//! ```
//!
//! Negative twin — adding a generic method makes the trait not dyn compatible (E0038):
//!
//! ```compile_fail
//! trait NotDynCompatible: Send + Sync { fn name(&self) -> String; fn pick<T>(&self, t: T) -> T; }
//! struct A;
//! impl NotDynCompatible for A { fn name(&self) -> String { "a".into() } fn pick<T>(&self, t: T) -> T { t } }
//! let erased: std::sync::Arc<dyn NotDynCompatible> = std::sync::Arc::new(A);
//! assert_eq!(erased.name(), "a");
//! ```

pub mod adapters;
pub mod composition;
pub mod contract;
pub mod ports;
pub mod service;
pub mod testing;
pub mod web;

pub use adapters::http::HttpProjectsPort;
pub use adapters::in_memory::InMemoryProjectsPort;
pub use composition::{build_projects_service, production_service};
pub use contract::{Project, ProjectQuery};
pub use ports::{PortError, ProjectsPort};
pub use service::{ErasedProjectsService, ProjectsService};
