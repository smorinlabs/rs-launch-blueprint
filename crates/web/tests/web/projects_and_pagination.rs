//! Integration tests for `/v1/projects` CRUD and first-party cursor pagination (`R01`, `R03`,
//! `R69`, `R72`).

use std::sync::Arc;

use axum::body::Body;
use axum::http::{Method, Request, StatusCode, header};
use rs_launch_blueprint_core::{InMemoryProjectsPort, Project, ProjectsService};
use rs_launch_blueprint_web::{
    AppState, ListResponse, PaginationLimits, WebSettings, build_router, decode_cursor,
    encode_cursor,
};
use tower::ServiceExt;

use crate::response_json;

fn seeded_projects(count: usize) -> Vec<Project> {
    (1..=count)
        .map(|i| Project {
            id: format!("prj_{i:04}"),
            name: format!("Project {i}"),
            workspace: Some(if i % 2 == 0 { "eng" } else { "ops" }.to_owned()),
        })
        .collect()
}

fn state_with_projects(projects: Vec<Project>) -> AppState {
    let port = Arc::new(InMemoryProjectsPort::with_projects(projects));
    let service = Arc::new(ProjectsService::new(
        port as Arc<dyn rs_launch_blueprint_core::ProjectsPort>,
    ));
    AppState::for_testing(service)
}

#[tokio::test]
async fn projects_crud_lifecycle_and_direct_domain_serialization() {
    let app = build_router(state_with_projects(Vec::new()));

    // Empty collection -> 200 OK with empty items and null next_cursor (R6.1, R6.2).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/projects")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    assert!(res.headers().contains_key(header::CACHE_CONTROL));
    assert!(!res.headers().contains_key(header::LINK));
    assert!(!res.headers().contains_key("x-total-count"));
    let body = response_json(res).await;
    assert_eq!(body["items"], serde_json::json!([]));
    assert!(body.as_object().unwrap().contains_key("next_cursor"));
    assert!(body["next_cursor"].is_null());

    // Create -> 201 Created + Location header (R5.6) + direct core Project wire model (R01).
    let create_req = Request::builder()
        .method(Method::POST)
        .uri("/v1/projects")
        .header(header::CONTENT_TYPE, "application/json")
        .body(Body::from(r#"{"name":"Alpha","workspace":"eng"}"#))
        .unwrap();
    let res = app.clone().oneshot(create_req).await.unwrap();
    assert_eq!(res.status(), StatusCode::CREATED);
    let location = res
        .headers()
        .get(header::LOCATION)
        .expect("POST create must emit Location header (R5.6)")
        .to_str()
        .unwrap()
        .to_owned();
    let created: Project = serde_json::from_value(response_json(res).await)
        .expect("response body must deserialize directly into core Project");
    assert_eq!(created.name, "Alpha");
    assert_eq!(created.workspace.as_deref(), Some("eng"));
    assert_eq!(location, format!("/v1/projects/{}", created.id));

    // Fetch single by Location -> 200 OK matching created Project byte-for-byte.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(&location)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let fetched: Project = serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(fetched, created);

    // List now contains the exact Project object.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/projects")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let listed: ListResponse<Project> = serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(listed.items, vec![created.clone()]);
    assert_eq!(listed.next_cursor, None);

    // Delete existing -> 204 No Content (R5.7).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::DELETE)
                .uri(&location)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::NO_CONTENT);

    // Subsequent GET and DELETE -> 404 RFC 9457 problem+json (RSLB301).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(&location)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::NOT_FOUND);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );
    let prob = response_json(res).await;
    assert_eq!(prob["code"], "resource_not_found");
    assert_eq!(prob["catalog_code"], "RSLB301");

    let res = app
        .oneshot(
            Request::builder()
                .method(Method::DELETE)
                .uri(&location)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn pagination_cursor_walk_workspace_filter_and_bounds() {
    // Seed 7 projects in scrambled order to verify deterministic ascending id sort (R6.6).
    let mut projects = seeded_projects(7);
    projects.reverse();
    let app = build_router(state_with_projects(projects));

    // Page 1: limit=3 -> items 1..=3 + non-null next_cursor.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/projects?limit=3")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    assert!(!res.headers().contains_key(header::LINK));
    assert!(!res.headers().contains_key("x-total-count"));
    let page1: ListResponse<Project> = serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(
        page1
            .items
            .iter()
            .map(|p| p.id.as_str())
            .collect::<Vec<_>>(),
        vec!["prj_0001", "prj_0002", "prj_0003"]
    );
    let cursor1 = page1.next_cursor.expect("page 1 must return next_cursor");
    assert_eq!(decode_cursor(&cursor1).unwrap(), "prj_0003");

    // Page 2: limit=3&cursor=<cursor1> -> items 4..=6.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(format!("/v1/projects?cursor={cursor1}&limit=3"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let page2: ListResponse<Project> = serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(
        page2
            .items
            .iter()
            .map(|p| p.id.as_str())
            .collect::<Vec<_>>(),
        vec!["prj_0004", "prj_0005", "prj_0006"]
    );
    let cursor2 = page2.next_cursor.expect("page 2 must return next_cursor");

    // Page 3 (last page): item 7, next_cursor: null.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(format!("/v1/projects?cursor={cursor2}&limit=3"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let body = response_json(res).await;
    assert!(body["next_cursor"].is_null());
    let page3: ListResponse<Project> = serde_json::from_value(body).unwrap();
    assert_eq!(
        page3
            .items
            .iter()
            .map(|p| p.id.as_str())
            .collect::<Vec<_>>(),
        vec!["prj_0007"]
    );

    // Cursor past the end -> 200 with empty items and null next_cursor (R6.2).
    let past_end = encode_cursor("prj_9999");
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(format!("/v1/projects?cursor={past_end}&limit=3"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let empty: ListResponse<Project> = serde_json::from_value(response_json(res).await).unwrap();
    assert!(empty.items.is_empty());
    assert!(empty.next_cursor.is_none());

    // Workspace filter coexists with pagination.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/projects?workspace=eng&limit=2")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let eng_page: ListResponse<Project> = serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(
        eng_page
            .items
            .iter()
            .map(|p| p.id.as_str())
            .collect::<Vec<_>>(),
        vec!["prj_0002", "prj_0004"]
    );
    assert!(eng_page.next_cursor.is_some());
}

#[tokio::test]
async fn pagination_defaults_validation_and_stream_rejection() {
    let projects = seeded_projects(60);
    let state = state_with_projects(projects);
    assert_eq!(state.pagination, PaginationLimits::default());
    let app = build_router(state);

    // Default limit is 50 (R72).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/projects")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let default_page: ListResponse<Project> =
        serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(default_page.items.len(), 50);
    assert!(default_page.next_cursor.is_some());

    // limit=0 and limit=101 -> 422 Unprocessable Entity (NEVER clamped, R5.3 / R11.1).
    for bad in ["limit=0", "limit=101"] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .uri(format!("/v1/projects?{bad}"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            res.status(),
            StatusCode::UNPROCESSABLE_ENTITY,
            "expected 422 for {bad}"
        );
        assert_eq!(
            res.headers().get(header::CONTENT_TYPE).unwrap(),
            "application/problem+json"
        );
        let prob = response_json(res).await;
        assert_eq!(prob["status"], 422);
        assert_eq!(prob["instance"], "/v1/projects");
        assert!(prob["errors"].is_array());
    }

    // limit=abc, malformed cursor, and stream=true -> 400 Bad Request (R5.3 / R13.3).
    for bad in [
        "limit=abc",
        "cursor=!!!not-base64!!!",
        "cursor=",
        "stream=true",
        "stream=false",
        "stream",
    ] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .uri(format!("/v1/projects?{bad}"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            res.status(),
            StatusCode::BAD_REQUEST,
            "expected 400 for {bad}"
        );
        assert_eq!(
            res.headers().get(header::CONTENT_TYPE).unwrap(),
            "application/problem+json"
        );
        let prob = response_json(res).await;
        assert_eq!(prob["status"], 400);
        // R5.17: instance carries path only, never query string.
        assert_eq!(prob["instance"], "/v1/projects");
    }
}

#[tokio::test]
async fn root_path_mounts_v1_under_prefix_while_keeping_probes_at_root() {
    let settings = WebSettings {
        root_path: "/api".to_owned(),
        ..WebSettings::default()
    };
    let state = state_with_projects(seeded_projects(2)).with_settings(settings);
    let app = build_router(state);

    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/v1/projects")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    let page: ListResponse<Project> = serde_json::from_value(response_json(res).await).unwrap();
    assert_eq!(page.items.len(), 2);

    // POST create under root_path prefixes Location with /api/v1/projects/{id}.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/api/v1/projects")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::from(r#"{"name":"Mounted"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::CREATED);
    let loc = res
        .headers()
        .get(header::LOCATION)
        .unwrap()
        .to_str()
        .unwrap();
    assert!(
        loc.starts_with("/api/v1/projects/"),
        "expected Location under root_path, got {loc}"
    );

    // /healthz remains mounted at root.
    let res = app
        .oneshot(
            Request::builder()
                .uri("/healthz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
}
