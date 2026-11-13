//! F121 — one suite body, three call sites: the shipped fake, the fake behind the erased boundary,
//! and the HTTP adapter talking to a live listener served by the fixture's own web adapter.
//! F001/F002 — the generic service accepts a concrete port and the erased port, and the erased
//! service satisfies the bounds a web framework's state requires.

use std::sync::Arc;

use seam_fixture::testing::{assert_projects_port_contract, sample_rows};
use seam_fixture::web::serve_in_background;
use seam_fixture::{
    ErasedProjectsService, HttpProjectsPort, InMemoryProjectsPort, Project, ProjectQuery,
    ProjectsPort, ProjectsService, build_projects_service,
};

#[test]
fn in_memory_adapter_satisfies_contract() {
    assert_projects_port_contract("in-memory", InMemoryProjectsPort::seeded);
}

#[test]
fn erased_in_memory_adapter_satisfies_contract() {
    assert_projects_port_contract("erased in-memory", |rows| {
        Arc::new(InMemoryProjectsPort::seeded(rows)) as Arc<dyn ProjectsPort>
    });
}

#[test]
fn http_adapter_against_live_listener_satisfies_contract() {
    assert_projects_port_contract("http adapter over live listener", |rows| {
        let upstream = build_projects_service(Arc::new(InMemoryProjectsPort::seeded(rows)));
        let addr = serve_in_background(upstream).expect("fixture web adapter binds 127.0.0.1:0");
        HttpProjectsPort::new(addr.to_string())
    });
}

#[test]
fn service_accepts_concrete_and_erased_ports() {
    let concrete = ProjectsService::new(InMemoryProjectsPort::seeded(sample_rows()));
    let erased: ErasedProjectsService =
        build_projects_service(Arc::new(InMemoryProjectsPort::seeded(sample_rows())));

    let from_concrete = concrete.search(&ProjectQuery::default()).unwrap();
    let from_erased = erased.search(&ProjectQuery::default()).unwrap();
    assert_eq!(
        from_concrete, from_erased,
        "static and erased dispatch produce the same value"
    );
    let ids: Vec<&str> = from_erased.iter().map(|p| p.id.as_str()).collect();
    assert_eq!(
        ids,
        ["1", "2", "3"],
        "use-case logic (sort by id) lives in the service, not the adapter"
    );
}

fn requires_web_state<S: Clone + Send + Sync + 'static>(_: &S) {}

#[test]
fn erased_service_is_clonable_shared_state() {
    let service = build_projects_service(Arc::new(InMemoryProjectsPort::seeded(sample_rows())));
    requires_web_state(&service);

    let moved = service.clone();
    let handle = std::thread::spawn(move || moved.find("1").unwrap());
    assert_eq!(
        handle.join().unwrap(),
        Some(Project {
            id: "1".into(),
            name: "alpha".into()
        })
    );
    assert_eq!(
        service.find("1").unwrap(),
        Some(Project {
            id: "1".into(),
            name: "alpha".into()
        })
    );
}
