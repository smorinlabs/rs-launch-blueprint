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

    // Absent by-id lookup translates to DomainError::NotFound (RSLB301).
    let err = svc
        .get_project("missing-42")
        .expect_err("missing project must error at service layer");
    assert_eq!(err.error_code(), ErrorCode::NotFound);
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

#[test]
fn port_doubles_service_helpers_and_composition_helpers_work() {
    use rs_launch_blueprint::{
        CreateProjectInput, Paths, ProjectsPort, default_credential_store, in_memory_service,
        workspace_info,
    };

    // workspace_info reports canonical standalone library metadata.
    let info = workspace_info();
    assert_eq!(info.package, "rs-launch-blueprint");
    assert_eq!(info.version, rs_launch_blueprint::VERSION);

    // InMemoryProjectsPort::default & set_failure across all 4 port methods.
    let mem = InMemoryProjectsPort::default();
    mem.set_failure(Some("injected".to_owned()))
        .expect("set failure");
    assert!(mem.list(&ProjectQuery::default()).is_err());
    assert!(mem.get("x").is_err());
    assert!(
        mem.create(&CreateProjectInput {
            name: "n".to_owned(),
            workspace: None,
        })
        .is_err()
    );
    assert!(mem.delete("x").is_err());
    mem.set_failure(None).expect("clear failure");

    // RecordingPort create, delete, clear_calls, into_inner.
    let spy = RecordingPort::new(mem);
    let created = spy
        .create(&CreateProjectInput {
            name: "Rec".to_owned(),
            workspace: Some("ws".to_owned()),
        })
        .expect("create");
    assert!(spy.delete(&created.id).expect("delete"));
    assert_eq!(spy.calls().len(), 2);
    spy.clear_calls();
    assert!(spy.calls().is_empty());
    let inner = spy.into_inner();
    assert!(inner.list(&ProjectQuery::default()).unwrap().is_empty());

    // ProjectsService clone, port(), find_project(), create_project(), delete_project(), and error propagation.
    let svc = in_memory_service([Project {
        id: "p1".to_owned(),
        name: "One".to_owned(),
        workspace: None,
    }]);
    let cloned = svc.clone();
    assert!(cloned.port().get("p1").unwrap().is_some());
    assert!(cloned.find_project("p1").unwrap().is_some());
    assert!(cloned.find_project("missing").unwrap().is_none());
    let created_svc = cloned
        .create_project(&CreateProjectInput {
            name: "Two".to_owned(),
            workspace: Some("core".to_owned()),
        })
        .expect("service create");
    cloned
        .delete_project(&created_svc.id)
        .expect("service delete");
    assert!(cloned.delete_project_if_exists("p1").unwrap());

    let failing_port = Arc::new(InMemoryProjectsPort::new());
    failing_port.set_failure(Some("outage".to_owned())).unwrap();
    let failing_svc = build_projects_service(failing_port);
    assert!(failing_svc.find_project("p1").is_err());
    assert!(
        failing_svc
            .create_project(&CreateProjectInput {
                name: "x".to_owned(),
                workspace: None,
            })
            .is_err()
    );
    assert!(failing_svc.delete_project("p1").is_err());
    assert!(failing_svc.delete_project_if_exists("p1").is_err());
    assert!(
        svc.create_project(&CreateProjectInput {
            name: "   ".to_owned(),
            workspace: None,
        })
        .is_err()
    );

    // default_credential_store composition helper.
    let paths = Paths::from_roots(
        "/tmp/c".into(),
        "/tmp/d".into(),
        "/tmp/s".into(),
        "/tmp/k".into(),
    );
    let store = default_credential_store(&paths);
    assert_eq!(store.path(), paths.credentials_file());

    #[cfg(feature = "keychain")]
    {
        let res = rs_launch_blueprint::keychain_credential_store("rslbp-test", "probe");
        if let Ok(kc) = res {
            assert!(format!("{kc:?}").contains("KeychainCredentialStore"));
        }
    }
}
