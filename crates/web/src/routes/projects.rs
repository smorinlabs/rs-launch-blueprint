//! `/v1/projects` REST CRUD handlers backed by synchronous [`ErasedProjectsService`] via
//! `tokio::task::spawn_blocking` (`R01`, `R05`, `R69`, `R70`, `R72`, `R73`).

use std::sync::Arc;

use axum::extract::State;
use axum::http::{HeaderValue, StatusCode, Uri, header};
use axum::middleware;
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use rs_launch_blueprint_core::{CreateProjectInput, ErasedProjectsService, ProjectQuery};

use crate::idempotency::{IdempotencyConfig, StoreDispatch, idempotency_middleware};
use crate::pagination::{Pagination, paginate_slice};
use crate::problems::{
    ProblemJson, ProblemPath, WebError, join_error_to_web_error, parse_query_pairs,
    reject_unsupported_query_params,
};
use crate::server::AppState;
use crate::settings::WebSettings;

fn extract_workspace_filter(uri: &Uri, base_uri: &str) -> Result<Option<String>, WebError> {
    let Some(raw_q) = uri.query() else {
        return Ok(None);
    };
    let pairs = parse_query_pairs(raw_q).unwrap_or_default();
    let mut workspace: Option<String> = None;
    for (k, v) in pairs {
        if k == "workspace" {
            if workspace.is_some() {
                return Err(WebError::framework(
                    StatusCode::BAD_REQUEST,
                    "invalid_query_parameter",
                    rs_launch_blueprint_core::ErrorCode::Usage,
                    "Duplicate 'workspace' query parameter.",
                    base_uri,
                    Some(uri.path()),
                ));
            }
            if let Some(val) = v
                && !val.is_empty()
            {
                workspace = Some(val);
            }
        }
    }
    Ok(workspace)
}

async fn run_blocking<T, F>(base_uri: &str, path: &str, op: F) -> Result<T, WebError>
where
    T: Send + 'static,
    F: FnOnce() -> Result<T, rs_launch_blueprint_core::DomainError> + Send + 'static,
{
    tokio::task::spawn_blocking(op)
        .await
        .map_err(|je| join_error_to_web_error(je, base_uri, path))?
        .map_err(|err| WebError::from_domain(&err, base_uri, Some(path)))
}

async fn list_projects(
    State(service): State<Arc<ErasedProjectsService>>,
    State(settings): State<WebSettings>,
    uri: Uri,
    Pagination(page_req): Pagination,
) -> Result<Response, WebError> {
    let base_uri = settings.problem_base_uri.clone();
    let path = uri.path().to_owned();
    let workspace = extract_workspace_filter(&uri, &base_uri)?;
    let query = ProjectQuery {
        workspace,
        limit: None,
    };

    let projects = run_blocking(&base_uri, &path, move || service.list_projects(&query)).await?;

    let page = paginate_slice(projects, &page_req, |p| p.id.as_str());
    Ok((
        StatusCode::OK,
        [(
            header::CACHE_CONTROL,
            HeaderValue::from_static("private, no-cache"),
        )],
        Json(page),
    )
        .into_response())
}

async fn create_project(
    State(service): State<Arc<ErasedProjectsService>>,
    State(settings): State<WebSettings>,
    uri: Uri,
    ProblemJson(input): ProblemJson<CreateProjectInput>,
) -> Result<Response, WebError> {
    let base_uri = settings.problem_base_uri.clone();
    let path = uri.path().to_owned();
    reject_unsupported_query_params(&uri, &base_uri, true)?;

    let created = run_blocking(&base_uri, &path, move || service.create_project(&input)).await?;

    let location_str = format!("{}/v1/projects/{}", settings.root_path, created.id);
    let mut response = (
        StatusCode::CREATED,
        [(header::CACHE_CONTROL, HeaderValue::from_static("no-store"))],
        Json(created),
    )
        .into_response();
    if let Ok(hv) = HeaderValue::from_str(&location_str) {
        response.headers_mut().insert(header::LOCATION, hv);
    }
    Ok(response)
}

async fn get_project(
    State(service): State<Arc<ErasedProjectsService>>,
    State(settings): State<WebSettings>,
    uri: Uri,
    ProblemPath(id): ProblemPath<String>,
) -> Result<Response, WebError> {
    let base_uri = settings.problem_base_uri.clone();
    let path = uri.path().to_owned();
    reject_unsupported_query_params(&uri, &base_uri, false)?;

    let project = run_blocking(&base_uri, &path, move || service.get_project(&id)).await?;

    Ok((
        StatusCode::OK,
        [(
            header::CACHE_CONTROL,
            HeaderValue::from_static("private, no-cache"),
        )],
        Json(project),
    )
        .into_response())
}

async fn delete_project(
    State(service): State<Arc<ErasedProjectsService>>,
    State(settings): State<WebSettings>,
    uri: Uri,
    ProblemPath(id): ProblemPath<String>,
) -> Result<Response, WebError> {
    let base_uri = settings.problem_base_uri.clone();
    let path = uri.path().to_owned();
    reject_unsupported_query_params(&uri, &base_uri, true)?;

    run_blocking(&base_uri, &path, move || service.delete_project(&id)).await?;

    Ok((
        StatusCode::NO_CONTENT,
        [(header::CACHE_CONTROL, HeaderValue::from_static("no-store"))],
    )
        .into_response())
}

pub(crate) fn router(state: &AppState) -> Router<AppState> {
    let idem_cfg = IdempotencyConfig {
        dispatch: StoreDispatch::Inline(Arc::clone(&state.idempotency)),
        max_body_bytes: state.settings.max_body_bytes,
        problem_base_uri: state.settings.problem_base_uri.clone(),
    };

    // Criterion 27 (R73): attach idempotency specifically to the `POST` MethodRouter branch
    // before merging with `GET` so unsupported methods (e.g. `PUT`) hit `405` before claiming.
    let post_projects = post(create_project).route_layer(middleware::from_fn_with_state(
        idem_cfg,
        idempotency_middleware,
    ));

    Router::new()
        .route("/v1/projects", get(list_projects).merge(post_projects))
        .route("/v1/projects/{id}", get(get_project).delete(delete_project))
}
