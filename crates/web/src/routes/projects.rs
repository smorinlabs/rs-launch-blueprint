//! `/v1/projects` REST CRUD handlers backed by synchronous [`ErasedProjectsService`] via
//! `tokio::task::spawn_blocking` (`R01`, `R05`, `R69`, `R70`, `R72`, `R73`).

use std::sync::Arc;

use axum::Json;
use axum::extract::State;
use axum::http::{HeaderValue, StatusCode, Uri, header};
use axum::middleware;
use axum::response::{IntoResponse, Response};
use rs_launch_blueprint_core::{CreateProjectInput, ErasedProjectsService, ProjectQuery};
use utoipa_axum::router::{OpenApiRouter, UtoipaMethodRouter};
use utoipa_axum::routes;

use crate::idempotency::{IdempotencyConfig, StoreDispatch, idempotency_middleware};
use crate::openapi::{CreateProjectInputSchema, Problem, ProjectListResponseSchema, ProjectSchema};
use crate::pagination::{Pagination, paginate_slice};
use crate::problems::{
    PROBLEM_CONTENT_TYPE, ProblemJson, ProblemPath, WebError, join_error_to_web_error,
    parse_query_pairs, reject_unsupported_query_params,
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
    let current_span = tracing::Span::current();
    tokio::task::spawn_blocking(move || current_span.in_scope(op))
        .await
        .map_err(|je| join_error_to_web_error(je, base_uri, path))?
        .map_err(|err| WebError::from_domain(&err, base_uri, Some(path)))
}

#[utoipa::path(
    get,
    path = "/v1/projects",
    tag = "projects",
    operation_id = "projects-list_projects",
    params(
        ("limit" = Option<u32>, Query, minimum = 1, maximum = 100, description = "Maximum number of projects per page (default 50, max 100)"),
        ("cursor" = Option<String>, Query, description = "Opaque URL-safe base64 pagination cursor"),
        ("workspace" = Option<String>, Query, description = "Optional workspace name filter")
    ),
    responses(
        (status = 200, description = "Cursor-paginated list of projects", body = ProjectListResponseSchema),
        (
            status = 422,
            description = "Validation error (e.g. out-of-range limit)",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        )
    )
)]
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

#[utoipa::path(
    post,
    path = "/v1/projects",
    tag = "projects",
    operation_id = "projects-create_project",
    params(
        ("Idempotency-Key" = Option<String>, Header, max_length = 255, description = "Optional caller-supplied idempotency key for safe retries")
    ),
    request_body(
        content = CreateProjectInputSchema,
        content_type = "application/json",
        description = "Project creation payload"
    ),
    responses(
        (status = 201, description = "Created project", body = ProjectSchema),
        (
            status = 409,
            description = "Resource conflict or idempotency key already in flight",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        ),
        (
            status = 415,
            description = "Unsupported media type",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        ),
        (
            status = 422,
            description = "Request body failed schema validation or idempotency payload mismatch",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        )
    )
)]
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

#[utoipa::path(
    get,
    path = "/v1/projects/{id}",
    tag = "projects",
    operation_id = "projects-get_project",
    params(
        ("id" = String, Path, min_length = 1, description = "Project identifier")
    ),
    responses(
        (status = 200, description = "Project found", body = ProjectSchema),
        (
            status = 404,
            description = "Project not found",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        )
    )
)]
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

#[utoipa::path(
    delete,
    path = "/v1/projects/{id}",
    tag = "projects",
    operation_id = "projects-delete_project",
    params(
        ("id" = String, Path, min_length = 1, description = "Project identifier")
    ),
    responses(
        (status = 204, description = "Project deleted"),
        (
            status = 404,
            description = "Project not found",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        )
    )
)]
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

pub(crate) fn router(state: &AppState) -> OpenApiRouter<AppState> {
    let idem_cfg = IdempotencyConfig {
        dispatch: StoreDispatch::Inline(Arc::clone(&state.idempotency)),
        max_body_bytes: state.settings.max_body_bytes,
        problem_base_uri: state.settings.problem_base_uri.clone(),
    };

    // Criterion 27 (R73): attach idempotency specifically to the `POST` MethodRouter branch
    // before merging with `GET` so unsupported methods (e.g. `PUT`) hit `405` before claiming,
    // while keeping both routes and OpenAPI operations bound through `routes!()` (R71 A8).
    let (mut projects_schemas, mut projects_paths, list_mr) = routes!(list_projects);
    let (create_schemas, create_paths, create_mr) = routes!(create_project);
    let create_mr = create_mr.route_layer(middleware::from_fn_with_state(
        idem_cfg,
        idempotency_middleware,
    ));
    projects_schemas.extend(create_schemas);
    for (path, item) in create_paths.paths {
        if let Some(existing) = projects_paths.paths.get_mut(&path) {
            existing.merge_operations(item);
        } else {
            projects_paths.paths.insert(path, item);
        }
    }
    let projects_collection: UtoipaMethodRouter<AppState> =
        (projects_schemas, projects_paths, list_mr.merge(create_mr));

    OpenApiRouter::new()
        .routes(projects_collection)
        .routes(routes!(get_project, delete_project))
}
