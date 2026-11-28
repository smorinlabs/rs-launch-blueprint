//! OpenAPI 3.1 contract snapshot drift, curated `operationId`, RFC 9457 error response, and
//! client-generator configuration tests (`R71` F307/F312/F332/F333, `R79`, `R84`).
//!
//! No file-level `#![cfg(feature = "web")]` because `crates/web` is an optional workspace member
//! (`R69` revision 11, `R71` revision 4).

use std::collections::BTreeSet;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;

use axum::body::{Body, to_bytes};
use axum::http::{Request, StatusCode, header};
use rs_launch_blueprint_core::{InMemoryProjectsPort, ProjectsPort, ProjectsService};
use rs_launch_blueprint_web::{
    API_DOCUMENT_VERSION, AppState, OPENAPI_PATH, build_router, openapi_json,
};
use serde_json::Value;
use tower::ServiceExt;

const SNAPSHOT: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../../openapi/openapi.json");

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../..")
        .canonicalize()
        .expect("canonicalize repo root")
}

fn empty_state() -> AppState {
    let port: Arc<dyn ProjectsPort> = Arc::new(InMemoryProjectsPort::new());
    AppState::for_testing(Arc::new(ProjectsService::new(port)))
}

/// Regenerate with:
/// `EXPECTORATE=overwrite cargo test --locked --workspace --features web --test openapi openapi_snapshot_is_current`
#[test]
fn openapi_snapshot_is_current() {
    expectorate::assert_contents(SNAPSHOT, &openapi_json());
}

#[test]
fn openapi_document_enforces_curated_operation_ids_problem_responses_version_constant_and_excludes_metrics()
 {
    let raw = openapi_json();
    // Determinism check (R71 A6): repeated generation is byte-identical.
    assert_eq!(raw, openapi_json());

    let doc: Value = serde_json::from_str(&raw).expect("OpenAPI document must be valid JSON");

    // R4.1 / R71: OpenAPI 3.1.0 with version-independent document constant ("0.0.0", A7).
    let spec_version = doc["openapi"].as_str().expect("openapi version string");
    assert!(
        spec_version.starts_with("3.1."),
        "OpenAPI version must be 3.1.x, got {spec_version}"
    );
    assert_eq!(
        doc["info"]["version"].as_str(),
        Some(API_DOCUMENT_VERSION),
        "info.version must stay pinned to API_DOCUMENT_VERSION so releases do not stale snapshot (A7)"
    );
    assert_eq!(API_DOCUMENT_VERSION, "0.0.0");

    // A2: Problem schema registered once under components.schemas.
    let schemas = doc["components"]["schemas"]
        .as_object()
        .expect("components.schemas object");
    assert!(
        schemas.contains_key("Problem"),
        "components.schemas must declare Problem (F307 A2)"
    );
    assert!(
        schemas.contains_key("Project"),
        "components.schemas must declare Project"
    );

    // R79: `/metrics` and `/openapi.json` must NEVER appear in the generated OpenAPI contract.
    let paths = doc["paths"].as_object().expect("paths object");
    assert!(
        !paths.contains_key("/metrics"),
        "/metrics must be excluded from OpenAPI schema (R79)"
    );
    assert!(
        !paths.contains_key(OPENAPI_PATH),
        "/openapi.json must not self-document in paths"
    );
    for expected in ["/healthz", "/readyz", "/v1/projects", "/v1/projects/{id}"] {
        assert!(
            paths.contains_key(expected),
            "expected documented route `{expected}` in paths: {:?}",
            paths.keys().collect::<Vec<_>>()
        );
    }

    // F312 (A3) + F307 (A1): every operation carries a unique `<first-tag>-<name>` operationId,
    // and every input-taking operation declares a 400 `application/problem+json` `$ref` to Problem.
    let mut seen_ids = BTreeSet::new();
    let mut operation_count = 0usize;
    let mut input_operation_count = 0usize;

    for (path, item) in paths {
        let item_obj = item.as_object().expect("path item must be JSON object");
        for method in ["get", "post", "put", "delete", "patch", "options", "head"] {
            let Some(op) = item_obj.get(method) else {
                continue;
            };
            operation_count += 1;
            let op_id = op["operationId"]
                .as_str()
                .unwrap_or_else(|| panic!("{method} {path} missing operationId (F312)"));
            assert!(
                !op_id.is_empty(),
                "{method} {path} operationId must be non-empty"
            );
            assert!(
                seen_ids.insert(op_id.to_owned()),
                "duplicate operationId `{op_id}` (F312)"
            );
            let first_tag = op["tags"]
                .as_array()
                .and_then(|arr| arr.first())
                .and_then(Value::as_str)
                .unwrap_or_else(|| panic!("{method} {path} missing tags (F312)"));
            let expected_prefix = format!("{first_tag}-");
            assert!(
                op_id.starts_with(&expected_prefix),
                "operationId `{op_id}` on {method} {path} lacks `{expected_prefix}` prefix (F312 A3)"
            );

            let has_params = op
                .get("parameters")
                .and_then(Value::as_array)
                .is_some_and(|p| !p.is_empty());
            let has_body = op.get("requestBody").is_some_and(|b| !b.is_null());
            if has_params || has_body {
                input_operation_count += 1;
                let resp_400 = &op["responses"]["400"];
                let ref_str = resp_400["content"]["application/problem+json"]["schema"]["$ref"]
                    .as_str()
                    .unwrap_or_else(|| {
                        panic!(
                            "{method} {path} takes input but lacks 400 application/problem+json $ref (F307 A1): {resp_400}"
                        )
                    });
                assert_eq!(ref_str, "#/components/schemas/Problem");
            }
        }
    }

    assert_eq!(operation_count, 6, "expected 6 documented operations");
    assert!(
        input_operation_count >= 4,
        "expected all 4 /v1/projects operations to take input and declare 400 Problem"
    );
}

#[tokio::test]
async fn served_openapi_endpoint_matches_committed_snapshot_and_rejects_stream() {
    let app = build_router(empty_state());

    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(OPENAPI_PATH)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/json"
    );
    assert!(res.headers().contains_key(header::CACHE_CONTROL));
    let body = to_bytes(res.into_body(), usize::MAX).await.unwrap();
    let served: Value = serde_json::from_slice(&body).expect("served OpenAPI must be valid JSON");
    let generated: Value = serde_json::from_str(&openapi_json()).unwrap();
    assert_eq!(
        served, generated,
        "served /openapi.json must match openapi_json()"
    );

    // R13.3: ?stream rejected with 400 problem+json on non-streaming endpoint.
    let bad = app
        .oneshot(
            Request::builder()
                .uri(format!("{OPENAPI_PATH}?stream=1"))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(bad.status(), StatusCode::BAD_REQUEST);
    assert_eq!(
        bad.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );

    // When `root_path` is set (e.g. "/api"), served `/openapi.json` prefixes project paths to
    // match the mounted router while keeping operational probes at the root.
    let settings = rs_launch_blueprint_web::WebSettings {
        root_path: "/api".to_owned(),
        ..rs_launch_blueprint_web::WebSettings::default()
    };
    let prefixed_app = build_router(empty_state().with_settings(settings));
    let prefixed_res = prefixed_app
        .oneshot(
            Request::builder()
                .uri(OPENAPI_PATH)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(prefixed_res.status(), StatusCode::OK);
    let prefixed_body = to_bytes(prefixed_res.into_body(), usize::MAX)
        .await
        .unwrap();
    let prefixed_doc: Value = serde_json::from_slice(&prefixed_body).unwrap();
    let prefixed_paths = prefixed_doc["paths"].as_object().unwrap();
    assert!(prefixed_paths.contains_key("/api/v1/projects"));
    assert!(prefixed_paths.contains_key("/api/v1/projects/{id}"));
    assert!(!prefixed_paths.contains_key("/v1/projects"));
    assert!(prefixed_paths.contains_key("/healthz"));
    assert!(prefixed_paths.contains_key("/readyz"));
}

#[test]
fn openapi_supporting_files_and_client_config_conform_to_r71_and_r84() {
    let root = repo_root();

    // R71 member 6: oasdiff severity override raises operationId removal to ERR.
    let levels = fs::read_to_string(root.join("openapi/oasdiff-levels.txt"))
        .expect("read openapi/oasdiff-levels.txt");
    assert!(
        levels
            .lines()
            .any(|l| l.trim() == "api-operation-id-removed err"),
        "openapi/oasdiff-levels.txt must raise api-operation-id-removed to err (R71)"
    );

    // R71 member 6: breaking-accepted.txt exists, documents the oasdiff --err-ignore format,
    // and permits reviewed non-comment exemption entries (A10).
    let accepted = fs::read_to_string(root.join("openapi/breaking-accepted.txt"))
        .expect("read openapi/breaking-accepted.txt");
    assert!(
        accepted.contains("--err-ignore"),
        "openapi/breaking-accepted.txt must document its oasdiff --err-ignore usage"
    );
    for (idx, line) in accepted.lines().enumerate() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        assert!(
            !trimmed.contains('\0'),
            "openapi/breaking-accepted.txt line {} contains invalid NUL byte",
            idx + 1
        );
    }

    // R84: openapi-to-rust.toml pins snapshot path, output dir, async client, and tracing off.
    let gen_cfg =
        fs::read_to_string(root.join("openapi-to-rust.toml")).expect("read openapi-to-rust.toml");
    for required in [
        "spec_path = \"openapi/openapi.json\"",
        "output_dir = \"clients/rust/src\"",
        "enable_async_client = true",
        "[http_client.tracing]",
        "enabled = false",
    ] {
        assert!(
            gen_cfg.contains(required),
            "openapi-to-rust.toml missing required R84 setting `{required}`"
        );
    }
}
