//! Integration tests for Prometheus RED metrics exposition at `/metrics` (`R79` rev 6, `OV-07`).

use std::sync::Arc;

use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use rs_launch_blueprint_core::{InMemoryProjectsPort, Project, ProjectsPort, ProjectsService};
use rs_launch_blueprint_web::{AppState, WebSettings, build_router};
use tower::ServiceExt;

fn state_with_settings(settings: WebSettings) -> AppState {
    let port: Arc<dyn ProjectsPort> = Arc::new(InMemoryProjectsPort::with_projects([Project {
        id: "p1".to_owned(),
        name: "Alpha".to_owned(),
        workspace: Some("eng".to_owned()),
    }]));
    AppState::for_testing(Arc::new(ProjectsService::new(port))).with_settings(settings)
}

#[cfg(not(feature = "metrics"))]
#[tokio::test]
async fn metrics_route_returns_404_when_metrics_feature_is_not_compiled() {
    let app = build_router(state_with_settings(WebSettings::default()));
    let res = app
        .oneshot(
            Request::builder()
                .uri("/metrics")
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
}

#[cfg(feature = "metrics")]
mod enabled {
    use super::*;
    use axum::body::to_bytes;
    use rs_launch_blueprint_web::{
        HTTP_REQUEST_DURATION_SECONDS, HTTP_UNMATCHED_REQUESTS_TOTAL, PROMETHEUS_CONTENT_TYPE,
        REQUEST_ID, RateLimitPolicy,
    };

    /// Validate Prometheus text exposition 0.0.4 syntax and histogram monotonicity (R79 AC7).
    fn assert_valid_prometheus_text(body: &str) {
        assert!(
            !body.trim().is_empty(),
            "Prometheus exposition body is empty"
        );
        for line in body.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }
            let mut parts = trimmed.split_whitespace();
            let metric_token = parts.next().expect("metric token");
            let value_token = parts.next().expect("metric value");
            assert!(
                !metric_token.is_empty(),
                "empty metric token on line: {line}"
            );
            let parsed: f64 = value_token.parse().unwrap_or_else(|err| {
                panic!("invalid Prometheus sample value `{value_token}` on `{line}`: {err}")
            });
            assert!(
                parsed.is_finite() && parsed >= 0.0,
                "expected finite non-negative metric value on `{line}`, got {parsed}"
            );
        }
    }

    #[tokio::test]
    async fn metrics_exposition_records_red_histograms_bounds_cardinality_and_excludes_ops() {
        let settings = WebSettings {
            rate_limit_per_ip: "1000/second".parse::<RateLimitPolicy>().unwrap(),
            rate_limit_per_ip_burst: std::num::NonZeroU32::new(1000).unwrap(),
            metrics_enabled: true,
            ..WebSettings::default()
        };
        let app = build_router(state_with_settings(settings));

        // 1. Drive 51 requests across 50 distinct path-parameter values (R79 AC1, AC4).
        for i in 0..51usize {
            let id = format!("item-{}", i % 50);
            let res = app
                .clone()
                .oneshot(
                    Request::builder()
                        .uri(format!("/v1/projects/{id}"))
                        .body(Body::empty())
                        .unwrap(),
                )
                .await
                .unwrap();
            assert_eq!(res.status(), StatusCode::NOT_FOUND);
        }

        // 2. Drive one 200 OK on templated `/v1/projects/p1`.
        let ok_res = app
            .clone()
            .oneshot(
                Request::builder()
                    .uri("/v1/projects/p1")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(ok_res.status(), StatusCode::OK);

        // 3. Drive unmatched paths -> must increment unmatched counter, NOT mint route labels (AC6).
        for random_path in ["/does-not-exist-a", "/scanner/random/999"] {
            let nf = app
                .clone()
                .oneshot(
                    Request::builder()
                        .uri(random_path)
                        .body(Body::empty())
                        .unwrap(),
                )
                .await
                .unwrap();
            assert_eq!(nf.status(), StatusCode::NOT_FOUND);
        }

        // 4. Drive operational probes -> must NOT appear in measured route series (R79).
        for probe in ["/healthz", "/readyz"] {
            let pr = app
                .clone()
                .oneshot(Request::builder().uri(probe).body(Body::empty()).unwrap())
                .await
                .unwrap();
            assert_eq!(pr.status(), StatusCode::OK);
        }

        // 5. Scrape `/metrics` twice across different Accept headers (OV-07(a), R7.1, R11.7).
        let mut last_body = String::new();
        for accept in [
            None,
            Some("application/json"),
            Some("text/plain;version=0.0.4;q=0.5,*/*;q=0.1"),
        ] {
            let mut req = Request::builder().uri("/metrics");
            if let Some(a) = accept {
                req = req.header(header::ACCEPT, a);
            }
            let res = app
                .clone()
                .oneshot(req.body(Body::empty()).unwrap())
                .await
                .unwrap();
            assert_eq!(res.status(), StatusCode::OK);
            assert_eq!(
                res.headers().get(header::CACHE_CONTROL).unwrap(),
                "private, no-cache"
            );
            assert_eq!(
                res.headers().get(header::CONTENT_TYPE).unwrap(),
                PROMETHEUS_CONTENT_TYPE
            );
            assert!(
                res.headers().contains_key(REQUEST_ID),
                "R11.7: /metrics must sit inside request-id middleware"
            );
            let bytes = to_bytes(res.into_body(), usize::MAX).await.unwrap();
            last_body = String::from_utf8(bytes.to_vec()).unwrap();
        }

        assert_valid_prometheus_text(&last_body);

        // AC1 & AC3: duration histogram buckets, _sum, _count carry template `/v1/projects/{id}`.
        assert!(
            last_body.contains(&format!("{HTTP_REQUEST_DURATION_SECONDS}_bucket")),
            "missing histogram buckets:\n{last_body}"
        );
        assert!(
            last_body.contains(&format!("{HTTP_REQUEST_DURATION_SECONDS}_sum")),
            "missing histogram _sum:\n{last_body}"
        );
        assert!(
            last_body.contains(&format!("{HTTP_REQUEST_DURATION_SECONDS}_count")),
            "missing histogram _count:\n{last_body}"
        );
        assert!(
            last_body.contains("http_route=\"/v1/projects/{id}\""),
            "expected templated http_route label:\n{last_body}"
        );
        assert!(
            last_body.contains("http_request_method=\"GET\""),
            "expected http_request_method label:\n{last_body}"
        );
        assert!(
            last_body.contains("http_response_status_code=\"200\"")
                && last_body.contains("http_response_status_code=\"404\""),
            "expected status code labels:\n{last_body}"
        );

        // AC4 & AC6: concrete path values and unmatched URIs MUST NEVER appear as labels!
        for forbidden in [
            "item-0",
            "item-49",
            "/v1/projects/p1",
            "does-not-exist-a",
            "scanner/random/999",
            "http_route=\"/metrics\"",
            "http_route=\"/healthz\"",
            "http_route=\"/readyz\"",
        ] {
            assert!(
                !last_body.contains(forbidden),
                "cardinality or exclusion violation: found `{forbidden}` in:\n{last_body}"
            );
        }

        // AC6: unmatched counter incremented with no route label.
        assert!(
            last_body.contains(&format!("{HTTP_UNMATCHED_REQUESTS_TOTAL} ")),
            "expected label-free {HTTP_UNMATCHED_REQUESTS_TOTAL} counter:\n{last_body}"
        );

        // AC9 (R13.3): `?stream` rejected with 400 + Cache-Control; `?streaming=1` still 200.
        for bad in [
            "/metrics?stream",
            "/metrics?stream=1",
            "/metrics?stream=false",
            "/metrics?a=1&stream=",
        ] {
            let res = app
                .clone()
                .oneshot(Request::builder().uri(bad).body(Body::empty()).unwrap())
                .await
                .unwrap();
            assert_eq!(
                res.status(),
                StatusCode::BAD_REQUEST,
                "expected 400 on {bad}"
            );
            assert_eq!(
                res.headers().get(header::CACHE_CONTROL).unwrap(),
                "private, no-cache"
            );
            assert_eq!(
                res.headers().get(header::CONTENT_TYPE).unwrap(),
                "application/problem+json"
            );
        }

        let ok_streaming = app
            .oneshot(
                Request::builder()
                    .uri("/metrics?streaming=1")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(ok_streaming.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn metrics_disabled_setting_returns_404_while_business_routes_serve() {
        // Ensure the global recorder is initialized so this test exercises the case where another
        // router in the same process enabled metrics while this router has metrics_enabled=false.
        let handle = rs_launch_blueprint_web::metrics_recorder();
        let parse_unmatched = |rendered: &str| -> u64 {
            rendered
                .lines()
                .find_map(|line| {
                    line.strip_prefix(&format!("{HTTP_UNMATCHED_REQUESTS_TOTAL} "))
                        .and_then(|v| v.trim().parse::<u64>().ok())
                })
                .unwrap_or(0)
        };
        let before = parse_unmatched(&handle.render());

        let settings = WebSettings {
            metrics_enabled: false,
            ..WebSettings::default()
        };
        let app = build_router(state_with_settings(settings));

        let m = app
            .clone()
            .oneshot(
                Request::builder()
                    .uri("/metrics")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(m.status(), StatusCode::NOT_FOUND);

        let nf = app
            .clone()
            .oneshot(
                Request::builder()
                    .uri("/disabled-router-unmatched")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(nf.status(), StatusCode::NOT_FOUND);

        let after = parse_unmatched(&handle.render());
        assert_eq!(
            after, before,
            "router with metrics_enabled=false must not increment unmatched counter"
        );

        let ok = app
            .oneshot(
                Request::builder()
                    .uri("/v1/projects")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(ok.status(), StatusCode::OK);
    }
}
