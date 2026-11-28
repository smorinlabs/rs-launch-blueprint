//! Slow-tier OpenAPI 3.1 contract fuzzing harness (`R83` revision 6, F334).
//!
//! Fetches the served `/openapi.json` document in-process via `tower::ServiceExt::oneshot`,
//! parses and validates it with `oas3`, enumerates every documented operation with zero hardcoded
//! route lists, generates 16 boundary-biased valid cases plus every enumerated boundary-invalid
//! constraint arm, and asserts:
//! - No 5xx server error (`R5.1`, `R83` P3)
//! - Registered HTTP status code (`R5.2`)
//! - Top-level JSON object on every JSON body (`R4.3`)
//! - RFC 9457 `application/problem+json` envelope on every non-2xx JSON response (`R5.12`/`R5.13`)
//!
//! Excluded from the default fast test run; execute via `just test-contract` or `just test-slow`.

mod common;

use std::sync::Arc;

use axum::body::{Body, to_bytes};
use axum::http::{Method, Request, header};
use proptest::test_runner::{Config, TestRunner};
use rs_launch_blueprint_core::{InMemoryProjectsPort, Project, ProjectsPort, ProjectsService};
use rs_launch_blueprint_web::{
    AppState, OPENAPI_PATH, PROBLEM_CONTENT_TYPE, RateLimitPolicy, WebSettings, build_router,
};
use serde_json::Value;
use tower::ServiceExt;

fn fuzz_router() -> axum::Router {
    let port: Arc<dyn ProjectsPort> = Arc::new(InMemoryProjectsPort::with_projects([Project {
        id: "prj-seed-1".to_owned(),
        name: "Seed Project".to_owned(),
        workspace: Some("eng".to_owned()),
    }]));
    let settings = WebSettings {
        // High burst so fuzzing tests route handlers rather than saturating the per-IP limiter.
        rate_limit_per_ip: "10000/second"
            .parse::<RateLimitPolicy>()
            .expect("parse high fuzz rate limit"),
        rate_limit_per_ip_burst: std::num::NonZeroU32::new(10_000).expect("non-zero burst"),
        ..WebSettings::default()
    };
    build_router(
        AppState::for_testing(Arc::new(ProjectsService::new(port))).with_settings(settings),
    )
}

fn assert_response_oracles(
    rt: &tokio::runtime::Runtime,
    op_id: &str,
    mode: &str,
    method: &Method,
    gen_req: &common::GeneratedRequest,
    response: axum::response::Response,
) {
    let status = response.status();
    let content_type = response
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_owned();
    let body_bytes = rt
        .block_on(to_bytes(response.into_body(), usize::MAX))
        .expect("read response body");
    let body_text = String::from_utf8_lossy(&body_bytes);

    // Oracle 1 (R5.1 / R83 P3): never return a 5xx server error.
    assert!(
        !status.is_server_error(),
        "[{op_id}][{mode}] 5xx server error ({status}) for {method} {:?}: {body_text}",
        gen_req
    );

    // Oracle 2 (R5.2): only registered HTTP status codes may be emitted.
    assert!(
        status.canonical_reason().is_some(),
        "[{op_id}][{mode}] unregistered HTTP status ({status}) for {method} {:?}",
        gen_req
    );

    // Oracle 3 (R4.3): every JSON response body must have an object at the top level.
    let is_json = content_type.contains("json");
    if is_json && !body_bytes.is_empty() {
        let parsed: Value = serde_json::from_slice(&body_bytes).unwrap_or_else(|err| {
            panic!("[{op_id}][{mode}] invalid JSON response ({err}): {body_text}")
        });
        assert!(
            parsed.is_object(),
            "[{op_id}][{mode}] JSON response must be top-level object (R4.3), got: {parsed}"
        );

        // Oracle 4 (R5.12 / R5.13): every non-2xx JSON response must be an RFC 9457 Problem.
        if !status.is_success() {
            assert!(
                content_type.starts_with(PROBLEM_CONTENT_TYPE),
                "[{op_id}][{mode}] non-2xx JSON response must be {PROBLEM_CONTENT_TYPE}, got `{content_type}`"
            );
            for key in ["type", "title", "status", "code", "catalog_code"] {
                assert!(
                    parsed.get(key).is_some(),
                    "[{op_id}][{mode}] RFC 9457 error missing `{key}`: {parsed}"
                );
            }
        }
    }
}

mod slow {
    use super::*;

    #[test]
    #[ignore = "slow OpenAPI contract fuzzing; run via `just test-contract` or `just test-slow`"]
    fn openapi_contract_fuzz_valid_and_boundary_invalid() {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("build current-thread runtime");

        let app = fuzz_router();

        // Discover schema from the served /openapi.json endpoint in process (R83 P1).
        let doc_res = rt
            .block_on(
                app.clone().oneshot(
                    Request::builder()
                        .uri(OPENAPI_PATH)
                        .body(Body::empty())
                        .unwrap(),
                ),
            )
            .expect("fetch /openapi.json");
        assert_eq!(doc_res.status(), axum::http::StatusCode::OK);
        let doc_bytes = rt
            .block_on(to_bytes(doc_res.into_body(), usize::MAX))
            .expect("read /openapi.json body");
        let spec = oas3::from_json(String::from_utf8(doc_bytes.to_vec()).unwrap())
            .expect("parse served OpenAPI 3.1 document");
        spec.validate_version()
            .expect("served OpenAPI version must match ~3.1 (R4.1)");

        let mut exercised_ops = 0usize;
        let mut runner = TestRunner::new(Config {
            cases: 16,
            failure_persistence: None,
            ..Config::default()
        });

        for (path, method, op) in spec.operations() {
            exercised_ops += 1;
            let op_id = op
                .operation_id
                .as_deref()
                .unwrap_or("<missing-operation-id>")
                .to_owned();

            // Mode 1: 16 boundary-biased valid cases via proptest TestRunner (shrinks on failure).
            let valid_strategy = common::operation_valid_request_strategy(&path, op, &spec);
            let run_result = runner.run(&valid_strategy, |gen_req| {
                let http_req = gen_req.to_http_request(&method);
                let resp = rt
                    .block_on(app.clone().oneshot(http_req))
                    .expect("oneshot valid request");
                assert_response_oracles(&rt, &op_id, "valid", &method, &gen_req, resp);
                Ok(())
            });
            assert!(
                run_result.is_ok(),
                "valid contract fuzz failed for `{op_id}`: {run_result:?}"
            );

            // Mode 2: deterministic enumeration of every declared boundary-invalid constraint arm.
            let invalid_cases = common::operation_boundary_invalid_requests(&path, op, &spec);
            for (arm, gen_req) in invalid_cases {
                let http_req = gen_req.to_http_request(&method);
                let resp = rt
                    .block_on(app.clone().oneshot(http_req))
                    .expect("oneshot boundary-invalid request");
                let mode = format!("boundary-invalid:{arm}");
                assert_response_oracles(&rt, &op_id, &mode, &method, &gen_req, resp);
            }
        }

        assert!(
            exercised_ops >= 6,
            "expected all documented operations to be enumerated from /openapi.json, got {exercised_ops}"
        );
    }
}
