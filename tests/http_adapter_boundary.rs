//! Loopback HTTP adapter contract and schema-drift tests using `httpmock` (`R01`, `R03`, `R05`,
//! `R48`).

use std::sync::{Arc, Mutex};

use httpmock::prelude::*;
use rs_launch_blueprint::{
    CreateProjectInput, DomainError, ErrorCode, Exit, HttpProjectsPort, PortError, Project,
    ProjectQuery, ProjectsPort, Token, assert_projects_port_contract, production_service,
};

#[test]
fn http_ureq_adapter_satisfies_projects_port_contract() {
    assert_projects_port_contract("http-ureq", |seed| {
        let server = MockServer::start();
        let state: Arc<Mutex<(Vec<Project>, u64)>> = Arc::new(Mutex::new((seed, 1000)));

        // GET /projects (collection with optional workspace & limit query params)
        {
            let state = Arc::clone(&state);
            server.mock(|when, then| {
                when.method(GET).path("/projects");
                then.respond_with(move |req: &HttpMockRequest| {
                    let guard = state.lock().expect("lock state");
                    let uri = req.uri();
                    let params = uri.query().unwrap_or("");
                    let mut workspace: Option<String> = None;
                    let mut limit: Option<usize> = None;
                    for pair in params.split('&').filter(|p| !p.is_empty()) {
                        if let Some((k, v)) = pair.split_once('=') {
                            match k {
                                "workspace" => workspace = Some(v.to_owned()),
                                "limit" => limit = v.parse().ok(),
                                _ => {}
                            }
                        }
                    }
                    let mut rows: Vec<serde_json::Value> = guard
                        .0
                        .iter()
                        .filter(|p| {
                            workspace
                                .as_deref()
                                .is_none_or(|ws| p.workspace.as_deref() == Some(ws))
                        })
                        .map(|p| {
                            serde_json::json!({
                                "gid": p.id,
                                "name": p.name,
                                "workspace": p.workspace.as_ref().map(|w| serde_json::json!({ "name": w })),
                            })
                        })
                        .collect();
                    if let Some(n) = limit {
                        rows.truncate(n);
                    }
                    let body = serde_json::json!({ "data": rows }).to_string();
                    HttpMockResponse::builder()
                        .status(200)
                        .header("content-type", "application/json")
                        .body(body)
                        .build()
                });
            });
        }

        // POST /projects
        {
            let state = Arc::clone(&state);
            server.mock(|when, then| {
                when.method(POST).path("/projects");
                then.respond_with(move |req: &HttpMockRequest| {
                    let payload: serde_json::Value =
                        serde_json::from_slice(req.body().as_ref()).unwrap_or_default();
                    let name = payload["name"].as_str().unwrap_or("").to_owned();
                    let workspace = payload["workspace"].as_str().map(str::to_owned);
                    let mut guard = state.lock().expect("lock state");
                    guard.1 += 1;
                    let id = format!("srv-{}", guard.1);
                    let project = Project {
                        id: id.clone(),
                        name: name.clone(),
                        workspace: workspace.clone(),
                    };
                    guard.0.push(project);
                    let body = serde_json::json!({
                        "data": {
                            "gid": id,
                            "name": name,
                            "workspace": workspace.map(|w| serde_json::json!({ "name": w })),
                        }
                    })
                    .to_string();
                    HttpMockResponse::builder()
                        .status(201)
                        .header("content-type", "application/json")
                        .body(body)
                        .build()
                });
            });
        }

        // GET /projects/{id}
        {
            let state = Arc::clone(&state);
            server.mock(|when, then| {
                when.method(GET).path_prefix("/projects/");
                then.respond_with(move |req: &HttpMockRequest| {
                    let uri = req.uri();
                    let id = uri.path().trim_start_matches("/projects/");
                    let guard = state.lock().expect("lock state");
                    match guard.0.iter().find(|p| p.id == id) {
                        Some(p) => {
                            let body = serde_json::json!({
                                "data": {
                                    "gid": p.id,
                                    "name": p.name,
                                    "workspace": p.workspace.as_ref().map(|w| serde_json::json!({ "name": w })),
                                }
                            })
                            .to_string();
                            HttpMockResponse::builder()
                                .status(200)
                                .header("content-type", "application/json")
                                .body(body)
                                .build()
                        }
                        None => HttpMockResponse::builder().status(404).build(),
                    }
                });
            });
        }

        // DELETE /projects/{id}
        {
            let state = Arc::clone(&state);
            server.mock(|when, then| {
                when.method(DELETE).path_prefix("/projects/");
                then.respond_with(move |req: &HttpMockRequest| {
                    let uri = req.uri();
                    let id = uri.path().trim_start_matches("/projects/");
                    let mut guard = state.lock().expect("lock state");
                    let before = guard.0.len();
                    guard.0.retain(|p| p.id != id);
                    if guard.0.len() < before {
                        HttpMockResponse::builder().status(204).build()
                    } else {
                        HttpMockResponse::builder().status(404).build()
                    }
                });
            });
        }

        struct ManagedHttpPort {
            _server: MockServer,
            inner: HttpProjectsPort,
        }
        impl ProjectsPort for ManagedHttpPort {
            fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
                self.inner.list(query)
            }
            fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
                self.inner.get(id)
            }
            fn create(&self, input: &CreateProjectInput) -> Result<Project, PortError> {
                self.inner.create(input)
            }
            fn delete(&self, id: &str) -> Result<bool, PortError> {
                self.inner.delete(id)
            }
        }

        let inner = HttpProjectsPort::new(server.base_url(), Token::new("contract-token"));
        ManagedHttpPort {
            _server: server,
            inner,
        }
    });
}

#[test]
fn http_production_service_sends_bearer_token_and_decodes_projects() {
    let server = MockServer::start();
    let mock = server.mock(|when, then| {
        when.method(GET)
            .path("/projects")
            .header("authorization", "Bearer prod-token-123")
            .header("accept", "application/json");
        then.status(200)
            .header("content-type", "application/json")
            .body(r#"{"data":[{"gid":101,"name":"Roadmap","workspace":{"name":"eng"}}]}"#);
    });

    let svc = production_service(server.base_url(), Token::new("prod-token-123"));
    let projects = svc
        .list_projects(&ProjectQuery::default())
        .expect("production service list");

    mock.assert();
    assert_eq!(
        projects,
        vec![Project {
            id: "101".to_owned(),
            name: "Roadmap".to_owned(),
            workspace: Some("eng".to_owned()),
        }]
    );
}

#[test]
fn http_adapter_boundary_maps_statuses_and_rejects_schema_drift() {
    let server = MockServer::start();

    // 404 on collection endpoint MUST be Err(RemoteApi), never Ok(vec![]) (R03 AC8).
    server.mock(|when, then| {
        when.method(GET).path("/projects");
        then.status(404);
    });

    // 404 on by-id endpoint -> Ok(None).
    server.mock(|when, then| {
        when.method(GET).path("/projects/absent");
        then.status(404);
    });

    // Malformed 200 JSON on by-id endpoint MUST be Err(RemoteApi), never Ok(None) (R03 AC9).
    server.mock(|when, then| {
        when.method(GET).path("/projects/bad-json");
        then.status(200).body("not valid json");
    });

    // Renamed envelope key (`results` instead of `data`) MUST fail loudly (R48 B6).
    server.mock(|when, then| {
        when.method(GET).path("/projects/drift-envelope");
        then.status(200)
            .header("content-type", "application/json")
            .body(r#"{"results":{"id":"1","name":"X"}}"#);
    });

    // Missing required `name` field MUST fail loudly.
    server.mock(|when, then| {
        when.method(GET).path("/projects/drift-missing-name");
        then.status(200)
            .header("content-type", "application/json")
            .body(r#"{"data":{"id":"1"}}"#);
    });

    // 401 -> Unauthorized (RSLB402 / exit 4).
    server.mock(|when, then| {
        when.method(GET).path("/projects/unauth");
        then.status(401);
    });

    // 409 -> Conflict (RSLB501 / exit 5).
    server.mock(|when, then| {
        when.method(POST).path("/projects");
        then.status(409);
    });

    // 500 -> RemoteApi (RSLB103 / exit 1).
    server.mock(|when, then| {
        when.method(GET).path("/projects/boom");
        then.status(500);
    });

    let port = HttpProjectsPort::new(server.base_url(), Token::new("tok"));

    let list_404 = port
        .list(&ProjectQuery::default())
        .expect_err("collection 404 must be error");
    assert_eq!(list_404.error_code(), ErrorCode::RemoteApi);

    assert_eq!(
        port.get("absent").expect("by-id 404 must be Ok(None)"),
        None
    );

    for bad_id in ["bad-json", "drift-envelope", "drift-missing-name", "boom"] {
        let err = port
            .get(bad_id)
            .expect_err(&format!("{bad_id} must return RemoteApi error"));
        assert_eq!(err.error_code(), ErrorCode::RemoteApi, "case {bad_id}");
    }

    let unauth = port.get("unauth").expect_err("401 must fail");
    assert_eq!(unauth.error_code(), ErrorCode::CredentialsRejected);

    let conflict = port
        .create(&CreateProjectInput {
            name: "dup".to_owned(),
            workspace: None,
        })
        .expect_err("409 must fail");
    assert_eq!(conflict.error_code(), ErrorCode::Conflict);

    // Closed port -> Transport error (RSLB102 / exit 1).
    let closed_listener = std::net::TcpListener::bind("127.0.0.1:0").expect("bind ephemeral");
    let closed_addr = closed_listener.local_addr().expect("local addr");
    drop(closed_listener);
    let broken_port = HttpProjectsPort::new(format!("http://{closed_addr}"), Token::new("tok"));
    let transport = broken_port
        .get("any")
        .expect_err("closed port must return Transport error");
    assert_eq!(transport.error_code(), ErrorCode::Transport);
    assert_eq!(DomainError::from(transport).exit(), Exit::Runtime);
}
