//! Contract tests for `ProjectsPort`, `ProjectsService`, fakes, spy, and optional `mockall`
//! (`R01`, `R03`, `R48`).
//!
//! Outbound HTTP adapter contract and schema-drift tests (`httpmock`) live in
//! `tests/http_adapter_boundary.rs`.

use std::num::NonZeroU32;
use std::sync::Arc;

use rs_launch_blueprint::{
    ErasedProjectsService, ErrorCode, InMemoryProjectsPort, PortCall, Project, ProjectQuery,
    ProjectsService, RecordingPort, assert_projects_port_contract, build_projects_service,
};

fn assert_web_state_bounds<T: Clone + Send + Sync + 'static>() {}

#[test]
fn erased_service_satisfies_web_state_bounds() {
    assert_web_state_bounds::<ErasedProjectsService>();
}

#[test]
fn in_memory_port_satisfies_projects_port_contract() {
    assert_projects_port_contract("in-memory", InMemoryProjectsPort::with_projects);
}

#[test]
fn service_translates_absence_to_not_found_and_empty_list_is_success() {
    let port = Arc::new(InMemoryProjectsPort::new());
    let svc = build_projects_service(port);

    // Empty collection read is Ok(vec![]), never NotFound (R03 AC6).
    let listed = svc
        .list_projects(&ProjectQuery::default())
        .expect("empty list must succeed");
    assert!(listed.is_empty());

    // Absent by-id lookup translates to DomainError::NotFound (RSLB301 / exit 3).
    let err = svc
        .get_project("missing-42")
        .expect_err("missing project must error at service layer");
    assert_eq!(err.error_code(), ErrorCode::NotFound);
    assert_eq!(err.exit(), rs_launch_blueprint::Exit::NotFound);
    assert!(err.to_string().contains("missing-42"));

    // delete_project translates Ok(false) -> NotFound; delete_project_if_exists returns Ok(false).
    let del_err = svc
        .delete_project("missing-42")
        .expect_err("delete_project on absent id must error");
    assert_eq!(del_err.error_code(), ErrorCode::NotFound);
    assert!(
        !svc.delete_project_if_exists("missing-42")
            .expect("delete_project_if_exists must succeed")
    );
}

#[test]
fn recording_port_captures_exact_queries_without_mock_crate() {
    let spy = Arc::new(RecordingPort::new(InMemoryProjectsPort::with_projects(
        vec![Project {
            id: "p1".to_owned(),
            name: "Alpha".to_owned(),
            workspace: Some("core".to_owned()),
        }],
    )));
    let svc = ProjectsService::new(Arc::clone(&spy));

    let query = ProjectQuery {
        workspace: Some("core".to_owned()),
        limit: NonZeroU32::new(5),
    };
    let rows = svc.list_projects(&query).expect("list");
    assert_eq!(rows.len(), 1);
    let _ = svc.get_project("p1").expect("get");

    assert_eq!(
        spy.calls(),
        vec![
            PortCall::List(query),
            PortCall::Get {
                id: "p1".to_owned(),
            },
        ]
    );
}

#[cfg(feature = "mock")]
#[test]
fn mockall_automock_distinguishes_absence_from_failure() {
    use rs_launch_blueprint::PortError;
    use rs_launch_blueprint_core::MockProjectsPort;

    let mut mock = MockProjectsPort::new();
    mock.expect_get()
        .withf(|id| id == "absent")
        .times(1)
        .returning(|_| Ok(None));
    mock.expect_get()
        .withf(|id| id == "broken")
        .times(1)
        .returning(|_| {
            Err(PortError::Unavailable {
                detail: "simulated outage".to_owned(),
            })
        });

    let svc = ProjectsService::new(mock);

    let err_absent = svc.get_project("absent").expect_err("absent -> NotFound");
    assert_eq!(err_absent.error_code(), ErrorCode::NotFound);

    let err_broken = svc.get_project("broken").expect_err("broken -> Io");
    assert_eq!(err_broken.error_code(), ErrorCode::Io);
}
