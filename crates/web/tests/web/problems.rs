//! Integration and contract tests for RFC 9457 `application/problem+json` error envelopes
//! (`R70`, REST API Design Standard v2.0.0 §5, criteria `R1`–`R24`).

use std::collections::BTreeSet;
use std::sync::Arc;

use axum::body::Body;
use axum::http::{HeaderValue, Method, Request, StatusCode, header};
use axum::response::IntoResponse;
use rs_launch_blueprint_core::{
    AuthError, DomainError, ErrorCode, InMemoryProjectsPort, PortError, ProjectsPort,
    ProjectsService,
};
use rs_launch_blueprint_web::{
    AppState, DEFAULT_PROBLEM_BASE_URI, FieldError, NOT_REQUEST_REACHABLE, PROBLEM_CONTENT_TYPE,
    WebError, WebSettings, build_router, detail_is_public, http_code, http_status,
    join_error_to_web_error, problem_catalog, problem_type,
};
use tower::ServiceExt;

use crate::response_json;

fn is_snake_case_code(s: &str) -> bool {
    let mut chars = s.chars();
    let Some(first) = chars.next() else {
        return false;
    };
    first.is_ascii_lowercase()
        && chars.all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_')
}

fn assert_valid_problem_document(body: &serde_json::Value, expected_status: u16) {
    let obj = body
        .as_object()
        .expect("problem document must be a JSON object (R4.3)");

    // Every member name must be snake_case and no member may be null (R4.4, R4.8, R21).
    for (k, v) in obj {
        assert!(
            k.chars()
                .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_'),
            "non-snake_case member `{k}` in problem body: {body}"
        );
        assert!(
            !v.is_null(),
            "member `{k}` must be omitted rather than null: {body}"
        );
    }

    let type_uri = obj
        .get("type")
        .and_then(|v| v.as_str())
        .expect("`type` MUST be present (R5.13.5)");
    assert_ne!(
        type_uri, "about:blank",
        "about:blank is forbidden (R5.13.5)"
    );
    assert!(
        type_uri.starts_with("https://"),
        "`type` must be an https URI: {type_uri}"
    );

    let code = obj
        .get("code")
        .and_then(|v| v.as_str())
        .expect("`code` MUST be present (R5.13.1)");
    assert!(is_snake_case_code(code), "invalid code grammar: {code}");
    assert!(
        type_uri.ends_with(&format!("/{}", code.replace('_', "-"))),
        "`type` ({type_uri}) must match template for `code` ({code})"
    );

    let catalog_code = obj
        .get("catalog_code")
        .and_then(|v| v.as_str())
        .expect("`catalog_code` MUST be present");
    assert_eq!(catalog_code.len(), 7);
    assert!(catalog_code.starts_with("RSLB"));

    assert_eq!(
        obj.get("status").and_then(|v| v.as_u64()),
        Some(u64::from(expected_status)),
        "`status` must equal HTTP status line"
    );
    assert!(
        obj.get("title")
            .and_then(|v| v.as_str())
            .is_some_and(|t| !t.is_empty()),
        "`title` must be non-empty"
    );

    if let Some(instance) = obj.get("instance").and_then(|v| v.as_str()) {
        assert!(
            !instance.contains('?'),
            "`instance` must carry path only, never query fragment (R5.17): {instance}"
        );
    }
}

#[test]
fn error_code_tables_are_total_injective_and_redaction_safe() {
    let mut seen_codes = BTreeSet::new();
    let mut seen_catalog = BTreeSet::new();

    for &ec in ErrorCode::ALL {
        let status = http_status(ec);
        assert!(
            status.is_client_error() || status.is_server_error(),
            "status for {ec} must be 4xx or 5xx, got {status}"
        );

        let code = http_code(ec);
        assert!(
            is_snake_case_code(code),
            "http_code({ec}) = `{code}` fails R5.13.1 grammar"
        );
        assert!(
            seen_codes.insert(code),
            "http_code must be injective; duplicate `{code}`"
        );
        assert!(seen_catalog.insert(ec.as_str()));

        let uri = problem_type(DEFAULT_PROBLEM_BASE_URI, code);
        assert!(uri.starts_with("https://"));
        assert_ne!(uri, "about:blank");
        assert!(uri.ends_with(&format!("/{}", code.replace('_', "-"))));

        // R3 (W5): NO 5xx code may be marked detail-public.
        if status.is_server_error() {
            assert!(
                !detail_is_public(ec),
                "5xx error code {ec} must NEVER be detail-public (W5)"
            );
        }
    }

    // All NOT_REQUEST_REACHABLE codes map to 500 and are non-public.
    assert_eq!(NOT_REQUEST_REACHABLE.len(), 4);
    for &ec in NOT_REQUEST_REACHABLE {
        assert_eq!(http_status(ec), StatusCode::INTERNAL_SERVER_ERROR);
        assert!(!detail_is_public(ec));
    }

    // R23: R5.16 catalog is generated from ErrorCode::ALL with 1-to-1 coverage.
    let catalog = problem_catalog(DEFAULT_PROBLEM_BASE_URI);
    assert_eq!(catalog.len(), ErrorCode::ALL.len());
    for (entry, &ec) in catalog.iter().zip(ErrorCode::ALL.iter()) {
        assert_eq!(entry.catalog_code, ec.as_str());
        assert_eq!(entry.code, http_code(ec));
        assert_eq!(entry.status, http_status(ec));
        assert_eq!(
            entry.problem_type,
            problem_type(DEFAULT_PROBLEM_BASE_URI, entry.code)
        );
    }
}

#[tokio::test]
async fn funnel_covers_404_405_415_400_422_502_500_without_leaking_values_or_internals() {
    let port = Arc::new(InMemoryProjectsPort::new());
    let service = Arc::new(ProjectsService::new(
        Arc::clone(&port) as Arc<dyn ProjectsPort>
    ));
    let settings = WebSettings {
        problem_base_uri: "https://errors.example.com/problems".to_owned(),
        ..WebSettings::default()
    };
    let app = build_router(AppState::for_testing(service).with_settings(settings));

    // 1. Router 404 miss with query string -> instance strips query (R19).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/does-not-exist?secret=super_secret_token")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::NOT_FOUND);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        PROBLEM_CONTENT_TYPE
    );
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 404);
    assert_eq!(body["instance"], "/v1/does-not-exist");
    assert!(!body.to_string().contains("super_secret_token"));

    // 2. Router 405 method not allowed preserves `Allow` header (RFC 9110 §15.5.6 / R5.11).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::PUT)
                .uri("/v1/projects")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        PROBLEM_CONTENT_TYPE
    );
    let allow = res
        .headers()
        .get(header::ALLOW)
        .expect("405 MUST carry Allow header")
        .to_str()
        .unwrap();
    assert!(allow.contains("GET") && allow.contains("POST"));
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 405);

    // 3. Missing JSON content type -> 415 Unsupported Media Type (R5.11).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/v1/projects")
                .header(header::CONTENT_TYPE, "text/plain")
                .body(Body::from(r#"{"name":"x"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        PROBLEM_CONTENT_TYPE
    );
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 415);

    // 4. Malformed JSON syntax -> 400 Bad Request, never echoing caller input (M-4 / R18).
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/v1/projects")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::from("{broken_secret_98765"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        PROBLEM_CONTENT_TYPE
    );
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 400);
    assert!(
        !body.to_string().contains("broken_secret_98765"),
        "R8.12 / M-4: malformed JSON body must never echo caller input: {body}"
    );

    // 5. Well-formed JSON with wrong field type -> 422 with `errors[]` array and NO value echo!
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/v1/projects")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::from(r#"{"name": 99887766}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        PROBLEM_CONTENT_TYPE
    );
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 422);
    assert!(
        !body.to_string().contains("99887766"),
        "R8.12 / M-4 / R18: serde type mismatch MUST NOT leak offending value: {body}"
    );
    let errors = body["errors"].as_array().expect("R5.15 errors array");
    assert!(!errors.is_empty());
    assert!(errors[0].get("pointer").and_then(|v| v.as_str()).is_some());
    assert!(errors[0].get("code").and_then(|v| v.as_str()).is_some());
    assert!(errors[0].get("detail").and_then(|v| v.as_str()).is_some());

    // 6. Per-endpoint `dry_run` guard on mutating routes that do not implement dry_run (R1.9 / R20).
    for (method, uri) in [
        (Method::POST, "/v1/projects?dry_run=true"),
        (Method::DELETE, "/v1/projects/1?dry_run=true"),
    ] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .method(method)
                    .uri(uri)
                    .header(header::CONTENT_TYPE, "application/json")
                    .body(Body::from(r#"{"name":"x"}"#))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::BAD_REQUEST, "R1.9 on {uri}");
        let body = response_json(res).await;
        assert_valid_problem_document(&body, 400);
    }

    // 7. Injected port failure -> 500 internal error redacting internal details (W5 / R8).
    port.set_failure(Some(
        "postgres://internal-db.corp:5432 secret_pw_123".to_owned(),
    ))
    .unwrap();
    let res = app
        .oneshot(
            Request::builder()
                .uri("/v1/projects")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::INTERNAL_SERVER_ERROR);
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 500);
    let text = body.to_string();
    assert!(!text.contains("internal-db.corp"));
    assert!(!text.contains("secret_pw_123"));
}

#[tokio::test]
async fn web_error_headers_documentation_and_join_error_redaction() {
    // 401 with WWW-Authenticate header + optional documentation member (R22).
    let err = WebError::from_domain(
        &DomainError::Auth(AuthError::CredentialsAbsent {
            detail: "missing bearer token".to_owned(),
        }),
        "https://errors.example.com",
        Some("/v1/projects"),
    )
    .with_header(
        header::WWW_AUTHENTICATE,
        HeaderValue::from_static("Bearer realm=\"rslbp\""),
    )
    .with_documentation("https://docs.example.com/auth")
    .with_errors(vec![FieldError {
        pointer: "/authorization".to_owned(),
        code: "missing_credential".to_owned(),
        detail: "Supply a valid bearer credential.".to_owned(),
    }]);

    let res = err.into_response();
    assert_eq!(res.status(), StatusCode::UNAUTHORIZED);
    assert_eq!(
        res.headers().get(header::WWW_AUTHENTICATE).unwrap(),
        "Bearer realm=\"rslbp\""
    );
    assert_eq!(
        res.headers().get(header::CACHE_CONTROL).unwrap(),
        "no-store"
    );
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 401);
    assert_eq!(body["code"], "credentials_absent");
    assert_eq!(body["catalog_code"], "RSLB401");
    assert_eq!(body["documentation"], "https://docs.example.com/auth");

    // 502 upstream failure hides internal hostname from response but keeps it in log_detail.
    let upstream = WebError::from_domain(
        &DomainError::Port(PortError::RemoteApi {
            detail: "upstream internal.vpc.local returned 500 with token=xyz".to_owned(),
            source: None,
        }),
        DEFAULT_PROBLEM_BASE_URI,
        Some("/v1/projects"),
    );
    assert!(
        upstream
            .log_detail()
            .is_some_and(|d| d.contains("internal.vpc.local"))
    );
    let res = upstream.into_response();
    assert_eq!(res.status(), StatusCode::BAD_GATEWAY);
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 502);
    assert!(!body.to_string().contains("internal.vpc.local"));
    assert!(!body.to_string().contains("token=xyz"));

    // Blocking bridge panic -> JoinError -> 500 hiding panic text (R14 / R05).
    let join_err = tokio::task::spawn_blocking(|| {
        panic!("SENSITIVE_PANIC_PAYLOAD_42");
    })
    .await
    .unwrap_err();
    let web_err = join_error_to_web_error(join_err, DEFAULT_PROBLEM_BASE_URI, "/v1/projects");
    let res = web_err.into_response();
    assert_eq!(res.status(), StatusCode::INTERNAL_SERVER_ERROR);
    let body = response_json(res).await;
    assert_valid_problem_document(&body, 500);
    assert!(!body.to_string().contains("SENSITIVE_PANIC_PAYLOAD_42"));
}
