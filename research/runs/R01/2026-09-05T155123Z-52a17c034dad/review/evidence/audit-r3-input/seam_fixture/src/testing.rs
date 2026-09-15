//! F121 — the substitutability suite: every behavioral assertion written once, as a generic function
//! over the port bound, called once per adapter from `tests/`. Monomorphization instantiates it per
//! adapter; the built-in harness reports one test per call site. No parametrization or mocking crate.

use crate::contract::{Project, ProjectQuery};
use crate::ports::ProjectsPort;

pub fn sample_rows() -> Vec<Project> {
    vec![
        Project {
            id: "2".into(),
            name: "beta".into(),
        },
        Project {
            id: "1".into(),
            name: "alpha".into(),
        },
        Project {
            id: "3".into(),
            name: "alphabet".into(),
        },
    ]
}

/// Assert the port contract against an adapter built from `make(seed_rows)`.
/// `label` names the adapter in every failure message so a shared assertion still reports which adapter broke.
pub fn assert_projects_port_contract<P: ProjectsPort>(
    label: &str,
    make: impl Fn(Vec<Project>) -> P,
) {
    let port = make(sample_rows());

    let all = port
        .list(&ProjectQuery::default())
        .unwrap_or_else(|e| panic!("[{label}] list(all) failed: {e}"));
    assert_eq!(
        all.len(),
        3,
        "[{label}] listing without a filter returns every seeded row"
    );

    let alpha = port
        .list(&ProjectQuery::matching("alpha"))
        .unwrap_or_else(|e| panic!("[{label}] list(alpha) failed: {e}"));
    let mut names: Vec<&str> = alpha.iter().map(|p| p.name.as_str()).collect();
    names.sort_unstable();
    assert_eq!(
        names,
        ["alpha", "alphabet"],
        "[{label}] substring filter matches both alpha rows"
    );

    let none = port
        .list(&ProjectQuery::matching("zzz"))
        .unwrap_or_else(|e| panic!("[{label}] list(zzz) failed: {e}"));
    assert!(
        none.is_empty(),
        "[{label}] an unmatched filter is an empty list, not an error"
    );

    let found = port
        .get("2")
        .unwrap_or_else(|e| panic!("[{label}] get(2) failed: {e}"));
    assert_eq!(
        found,
        Some(Project {
            id: "2".into(),
            name: "beta".into()
        }),
        "[{label}] get returns the seeded row by id"
    );

    let missing = port
        .get("404")
        .unwrap_or_else(|e| panic!("[{label}] get(404) failed: {e}"));
    assert_eq!(
        missing, None,
        "[{label}] get of an unknown id is None (placeholder shape; R03 decides)"
    );

    let empty = make(Vec::new());
    let rows = empty
        .list(&ProjectQuery::default())
        .unwrap_or_else(|e| panic!("[{label}] list on empty failed: {e}"));
    assert!(
        rows.is_empty(),
        "[{label}] an empty backing store lists nothing"
    );
}
