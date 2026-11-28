//! Driven-I/O port trait, first-class in-memory fake, spy wrapper, and shared substitutability
//! contract suite (`R01`, `R03`, `R48`).

use std::num::NonZeroU32;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

use crate::error::PortError;
use crate::models::{CreateProjectInput, Project, ProjectQuery};

/// Driven-I/O port for project storage and remote APIs (`R01`, `R03`, `R05`).
///
/// Kept strictly dyn-compatible (synchronous methods, no generics, no non-receiver `Self`) so
/// the composition root can erase concrete adapters to `Arc<dyn ProjectsPort>`.
///
/// Absence on by-identity reads returns `Ok(None)`; transport and protocol failures return `Err`.
#[cfg_attr(feature = "mock", mockall::automock)]
pub trait ProjectsPort: Send + Sync {
    /// List projects matching `query`. An empty `Vec` is a complete answer, never an absence.
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError>;

    /// Fetch one project by identity. `Ok(None)` means authoritatively absent.
    fn get(&self, id: &str) -> Result<Option<Project>, PortError>;

    /// Create a new project and return the persisted representation.
    fn create(&self, input: &CreateProjectInput) -> Result<Project, PortError>;

    /// Delete a project by identity. Returns `Ok(true)` if deleted or `Ok(false)` if absent.
    fn delete(&self, id: &str) -> Result<bool, PortError>;
}

impl<T: ProjectsPort + ?Sized> ProjectsPort for Arc<T> {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        (**self).list(query)
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        (**self).get(id)
    }

    fn create(&self, input: &CreateProjectInput) -> Result<Project, PortError> {
        (**self).create(input)
    }

    fn delete(&self, id: &str) -> Result<bool, PortError> {
        (**self).delete(id)
    }
}

/// Shipped first-class in-memory [`ProjectsPort`] implementation (`R01` F013).
///
/// Unconditional public library item (no `cfg(test)` or feature gate). Uses `std::sync::Mutex`
/// and maps a poisoned lock to [`PortError::Unavailable`] rather than panicking.
#[derive(Debug)]
pub struct InMemoryProjectsPort {
    rows: Mutex<Vec<Project>>,
    next_id: AtomicU64,
    injected_failure: Mutex<Option<String>>,
}

impl Default for InMemoryProjectsPort {
    fn default() -> Self {
        Self::new()
    }
}

fn lock_port<'a, T>(
    mutex: &'a Mutex<T>,
    detail: &str,
) -> Result<std::sync::MutexGuard<'a, T>, PortError> {
    mutex.lock().map_err(|_| PortError::Unavailable {
        detail: detail.to_owned(),
    })
}

impl InMemoryProjectsPort {
    /// Create an empty in-memory projects store.
    #[must_use]
    pub fn new() -> Self {
        Self {
            rows: Mutex::new(Vec::new()),
            next_id: AtomicU64::new(1),
            injected_failure: Mutex::new(None),
        }
    }

    /// Create an in-memory projects store seeded with initial rows.
    #[must_use]
    pub fn with_projects(projects: impl IntoIterator<Item = Project>) -> Self {
        let rows: Vec<Project> = projects.into_iter().collect();
        let start = (rows.len() as u64).saturating_add(1);
        Self {
            rows: Mutex::new(rows),
            next_id: AtomicU64::new(start),
            injected_failure: Mutex::new(None),
        }
    }

    /// Configure a fault detail returned as [`PortError::Unavailable`] by subsequent calls
    /// (`R48` B2 error injection). Pass `None` to clear the fault.
    pub fn set_failure(&self, detail: Option<String>) -> Result<(), PortError> {
        let mut guard = lock_port(&self.injected_failure, "in-memory failure lock poisoned")?;
        *guard = detail;
        Ok(())
    }

    fn check_failure(&self) -> Result<(), PortError> {
        let guard = lock_port(&self.injected_failure, "in-memory failure lock poisoned")?;
        if let Some(detail) = guard.as_ref() {
            return Err(PortError::Unavailable {
                detail: detail.clone(),
            });
        }
        Ok(())
    }
}

impl ProjectsPort for InMemoryProjectsPort {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        self.check_failure()?;
        let guard = lock_port(&self.rows, "in-memory projects lock poisoned")?;
        let limit = query.limit_or_default() as usize;
        let matched = guard
            .iter()
            .filter(|project| {
                query
                    .workspace
                    .as_deref()
                    .is_none_or(|ws| project.workspace.as_deref() == Some(ws))
            })
            .take(limit)
            .cloned()
            .collect();
        Ok(matched)
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        self.check_failure()?;
        let guard = lock_port(&self.rows, "in-memory projects lock poisoned")?;
        Ok(guard.iter().find(|project| project.id == id).cloned())
    }

    fn create(&self, input: &CreateProjectInput) -> Result<Project, PortError> {
        self.check_failure()?;
        let mut guard = lock_port(&self.rows, "in-memory projects lock poisoned")?;
        let id = format!("mem-{}", self.next_id.fetch_add(1, Ordering::Relaxed));
        let project = Project {
            id,
            name: input.name.clone(),
            workspace: input.workspace.clone(),
        };
        guard.push(project.clone());
        Ok(project)
    }

    fn delete(&self, id: &str) -> Result<bool, PortError> {
        self.check_failure()?;
        let mut guard = lock_port(&self.rows, "in-memory projects lock poisoned")?;
        let before = guard.len();
        guard.retain(|project| project.id != id);
        Ok(guard.len() < before)
    }
}

/// Recorded invocation observed by [`RecordingPort`] (`R48` B3).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PortCall {
    /// Call to [`ProjectsPort::list`].
    List(ProjectQuery),
    /// Call to [`ProjectsPort::get`].
    Get {
        /// Requested project identifier.
        id: String,
    },
    /// Call to [`ProjectsPort::create`].
    Create(CreateProjectInput),
    /// Call to [`ProjectsPort::delete`].
    Delete {
        /// Requested project identifier.
        id: String,
    },
}

/// Generic spy wrapper recording every call forwarded to an inner [`ProjectsPort`] (`R48`).
#[derive(Debug)]
pub struct RecordingPort<P> {
    inner: P,
    calls: Mutex<Vec<PortCall>>,
}

impl<P> RecordingPort<P> {
    /// Wrap `inner` with an empty call log.
    #[must_use]
    pub fn new(inner: P) -> Self {
        Self {
            inner,
            calls: Mutex::new(Vec::new()),
        }
    }

    /// Return a snapshot of all recorded port calls in invocation order.
    #[must_use]
    pub fn calls(&self) -> Vec<PortCall> {
        self.calls
            .lock()
            .map(|guard| guard.clone())
            .unwrap_or_default()
    }

    /// Clear the recorded call log.
    pub fn clear_calls(&self) {
        if let Ok(mut guard) = self.calls.lock() {
            guard.clear();
        }
    }

    /// Unwrap and return the inner port.
    #[must_use]
    pub fn into_inner(self) -> P {
        self.inner
    }

    fn record(&self, call: PortCall) -> Result<(), PortError> {
        let mut guard = lock_port(&self.calls, "recording port lock poisoned")?;
        guard.push(call);
        Ok(())
    }
}

impl<P: ProjectsPort> ProjectsPort for RecordingPort<P> {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        self.record(PortCall::List(query.clone()))?;
        self.inner.list(query)
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        self.record(PortCall::Get { id: id.to_owned() })?;
        self.inner.get(id)
    }

    fn create(&self, input: &CreateProjectInput) -> Result<Project, PortError> {
        self.record(PortCall::Create(input.clone()))?;
        self.inner.create(input)
    }

    fn delete(&self, id: &str) -> Result<bool, PortError> {
        self.record(PortCall::Delete { id: id.to_owned() })?;
        self.inner.delete(id)
    }
}

/// Shared substitutability contract suite run against every [`ProjectsPort`] implementation
/// (`R01` F121, `R03` rule 6).
///
/// # Panics
///
/// Panics with a diagnostic naming `label` if the adapter violates any port invariant.
pub fn assert_projects_port_contract<P: ProjectsPort>(
    label: &str,
    make: impl Fn(Vec<Project>) -> P,
) {
    // 1. Empty collection read is Ok(vec![]), never an error (R03).
    let empty = make(Vec::new());
    let empty_rows = expect_contract_ok(
        empty.list(&ProjectQuery::default()),
        label,
        "empty list must return Ok(vec![])",
    );
    assert!(
        empty_rows.is_empty(),
        "[{label}] expected empty list from empty store, got {empty_rows:?}"
    );

    // 2. Seeded reads, workspace filtering, and limit enforcement.
    let seed = vec![
        Project {
            id: "1".to_owned(),
            name: "Alpha".to_owned(),
            workspace: Some("eng".to_owned()),
        },
        Project {
            id: "2".to_owned(),
            name: "Beta".to_owned(),
            workspace: Some("eng".to_owned()),
        },
        Project {
            id: "3".to_owned(),
            name: "Gamma".to_owned(),
            workspace: Some("ops".to_owned()),
        },
    ];
    let port = make(seed);

    let all = expect_contract_ok(port.list(&ProjectQuery::default()), label, "list all");
    assert_eq!(all.len(), 3, "[{label}] expected 3 seeded projects");

    let eng = expect_contract_ok(
        port.list(&ProjectQuery {
            workspace: Some("eng".to_owned()),
            limit: None,
        }),
        label,
        "list by workspace",
    );
    assert_eq!(eng.len(), 2, "[{label}] expected 2 eng projects");

    let limited = expect_contract_ok(
        port.list(&ProjectQuery {
            workspace: Some("eng".to_owned()),
            limit: NonZeroU32::new(1),
        }),
        label,
        "list with limit",
    );
    assert_eq!(limited.len(), 1, "[{label}] expected limit=1 to cap rows");

    // 3. By-identity read: present -> Ok(Some), absent -> Ok(None) (R03 rule 1).
    let found = expect_contract_ok(port.get("1"), label, "get existing");
    assert_eq!(
        found.as_ref().map(|p| p.name.as_str()),
        Some("Alpha"),
        "[{label}] get('1') returned wrong project"
    );

    let absent = expect_contract_ok(port.get("nonexistent-id"), label, "get absent");
    assert_eq!(
        absent, None,
        "[{label}] get('nonexistent-id') must be Ok(None)"
    );

    // 4. Create then retrieve.
    let created = expect_contract_ok(
        port.create(&CreateProjectInput {
            name: "Delta".to_owned(),
            workspace: Some("ops".to_owned()),
        }),
        label,
        "create",
    );
    assert_eq!(created.name, "Delta", "[{label}] created name mismatch");
    let fetched = expect_contract_ok(port.get(&created.id), label, "get created");
    assert_eq!(
        fetched,
        Some(created.clone()),
        "[{label}] created project must be retrievable"
    );

    // 5. Delete present -> Ok(true) and then Ok(None); delete absent -> Ok(false).
    let deleted = expect_contract_ok(port.delete(&created.id), label, "delete existing");
    assert!(deleted, "[{label}] delete of existing id must return true");

    let after_delete = expect_contract_ok(port.get(&created.id), label, "get after delete");
    assert_eq!(
        after_delete, None,
        "[{label}] deleted project must return Ok(None)"
    );

    let deleted_again = expect_contract_ok(port.delete(&created.id), label, "delete absent");
    assert!(
        !deleted_again,
        "[{label}] delete of absent id must return false"
    );
}

fn expect_contract_ok<T, E: std::fmt::Display>(res: Result<T, E>, label: &str, step: &str) -> T {
    match res {
        Ok(val) => val,
        Err(err) => panic!("[{label}] {step} failed: {err}"),
    }
}
