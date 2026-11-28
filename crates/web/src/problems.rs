//! RFC 9457 `application/problem+json` error envelope mapping and problem-aware extractors (`R70`).
//!
//! This module is the **only** file in `crates/web` that imports [`problem_details`]. Every domain
//! error, router fallback, extractor rejection, timeout, payload-size violation, panic recovery,
//! rate-limit refusal, and readiness failure funnels through [`WebError`].

use std::fmt;

use axum::extract::rejection::{JsonRejection, PathRejection, QueryRejection};
use axum::extract::{FromRef, FromRequest, FromRequestParts, Json, Path, Query, Request};
use axum::http::request::Parts;
use axum::http::{HeaderMap, HeaderName, HeaderValue, StatusCode, Uri, header};
use axum::response::{IntoResponse, Response};
use problem_details::ProblemDetails;
use rs_launch_blueprint_core::{Diagnostics, DomainError, ErrorCode};
use serde::Serialize;
use serde::de::DeserializeOwned;
use tokio::task::JoinError;

use crate::settings::WebSettings;

/// RFC 9457 media type emitted on every error response (`R70`).
pub const PROBLEM_CONTENT_TYPE: &str = "application/problem+json";

/// CLI- and process-lifecycle-only [`ErrorCode`] variants that cannot be reached from a valid HTTP
/// request handler (`R70`).
///
/// All four map to `500 Internal Server Error` and are never detail-public.
pub const NOT_REQUEST_REACHABLE: &[ErrorCode] = &[
    ErrorCode::ConfigUnreadable,
    ErrorCode::SigInt,
    ErrorCode::SigTerm,
    ErrorCode::PromptInterrupted,
];

/// Structured per-field validation entry emitted inside `errors[]` (`R5.15`, `R70`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, utoipa::ToSchema)]
pub struct FieldError {
    /// RFC 6901 JSON Pointer locating the offending field or parameter (e.g. `"/name"`).
    pub pointer: String,
    /// Stable lowercase snake_case machine code describing the rule violated.
    pub code: String,
    /// Sanitized human-readable explanation (never echoing caller values).
    pub detail: String,
}

/// Typed RFC 9457 extension members flattened onto every problem response (`R70`).
///
/// Every optional member uses `skip_serializing_if` so absent fields are omitted rather than
/// serialized as `null`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ProblemExt {
    /// Stable lowercase snake_case HTTP error code (`R5.13.1`).
    pub code: String,
    /// Stable `RSLB###` cross-surface catalog code (`R67`).
    pub catalog_code: String,
    /// Optional HTTPS documentation link (`R5.13.4`).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub documentation: Option<String>,
    /// Optional structured field validation errors (`R5.15`).
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub errors: Vec<FieldError>,
    /// Optional redacted readiness diagnostics payload emitted by `/readyz` `503` (`R70` rev 5, `R80`).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub diagnostics: Option<Diagnostics>,
}

/// One row of the generated `R5.16` error catalog (`R70`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ProblemCatalogEntry {
    /// Stable `RSLB###` catalog code.
    pub catalog_code: &'static str,
    /// Stable lowercase snake_case HTTP error code.
    pub code: &'static str,
    /// HTTP status code mapped to this error.
    #[serde(serialize_with = "serialize_status_code")]
    pub status: StatusCode,
    /// Full HTTPS RFC 9457 `type` URI derived from the configured base URI.
    pub problem_type: String,
    /// Whether this error's domain message is safe to expose in `detail` (`false` for all 5xx).
    pub detail_is_public: bool,
}

fn serialize_status_code<S: serde::Serializer>(
    status: &StatusCode,
    serializer: S,
) -> Result<S::Ok, S::Error> {
    serializer.serialize_u16(status.as_u16())
}

/// Total mapping from [`ErrorCode`] to HTTP [`StatusCode`] (`R70`).
#[must_use]
pub const fn http_status(code: ErrorCode) -> StatusCode {
    match code {
        ErrorCode::Unexpected
        | ErrorCode::Io
        | ErrorCode::ConfigUnreadable
        | ErrorCode::ConfigUnparsable
        | ErrorCode::ConfigInvalid
        | ErrorCode::SigInt
        | ErrorCode::SigTerm
        | ErrorCode::PromptInterrupted => StatusCode::INTERNAL_SERVER_ERROR,
        ErrorCode::Transport | ErrorCode::RemoteApi => StatusCode::BAD_GATEWAY,
        ErrorCode::Usage | ErrorCode::ProhibitedSecretChannel | ErrorCode::InputUnavailable => {
            StatusCode::BAD_REQUEST
        }
        ErrorCode::NotFound => StatusCode::NOT_FOUND,
        ErrorCode::CredentialsAbsent | ErrorCode::CredentialsRejected => StatusCode::UNAUTHORIZED,
        ErrorCode::Conflict => StatusCode::CONFLICT,
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

/// Total, injective mapping from [`ErrorCode`] to lowercase snake_case HTTP `code` (`R70`).
#[must_use]
pub const fn http_code(code: ErrorCode) -> &'static str {
    match code {
        ErrorCode::Unexpected => "internal_error",
        ErrorCode::Io => "storage_io_error",
        ErrorCode::Transport => "upstream_transport_error",
        ErrorCode::RemoteApi => "upstream_api_error",
        ErrorCode::ConfigUnreadable => "config_unreadable",
        ErrorCode::Usage => "invalid_request",
        ErrorCode::ConfigUnparsable => "config_unparsable",
        ErrorCode::ConfigInvalid => "config_invalid",
        ErrorCode::ProhibitedSecretChannel => "prohibited_secret_channel",
        ErrorCode::InputUnavailable => "input_unavailable",
        ErrorCode::NotFound => "resource_not_found",
        ErrorCode::CredentialsAbsent => "credentials_absent",
        ErrorCode::CredentialsRejected => "credentials_rejected",
        ErrorCode::Conflict => "resource_conflict",
        ErrorCode::SigInt => "process_interrupted",
        ErrorCode::SigTerm => "process_terminated",
        ErrorCode::PromptInterrupted => "prompt_interrupted",
        _ => "unknown_error",
    }
}

/// Return `true` only when a domain error message for `code` is safe to surface in HTTP `detail`.
///
/// Invariant `W5` (`R70`): every `5xx` status code returns `false`.
#[must_use]
pub const fn detail_is_public(code: ErrorCode) -> bool {
    match code {
        ErrorCode::Usage
        | ErrorCode::ProhibitedSecretChannel
        | ErrorCode::InputUnavailable
        | ErrorCode::NotFound
        | ErrorCode::CredentialsAbsent
        | ErrorCode::Conflict => true,
        ErrorCode::Unexpected
        | ErrorCode::Io
        | ErrorCode::Transport
        | ErrorCode::RemoteApi
        | ErrorCode::ConfigUnreadable
        | ErrorCode::ConfigUnparsable
        | ErrorCode::ConfigInvalid
        | ErrorCode::CredentialsRejected
        | ErrorCode::SigInt
        | ErrorCode::SigTerm
        | ErrorCode::PromptInterrupted => false,
        _ => false,
    }
}

/// Construct the canonical RFC 9457 `type` URI from `base_uri` and lowercase snake_case `code`.
#[must_use]
pub fn problem_type(base_uri: &str, code: &str) -> String {
    let trimmed = base_uri.trim_end_matches('/');
    let slug = code.replace('_', "-");
    format!("{trimmed}/{slug}")
}

/// Generate the full `R5.16` problem catalog directly from [`ErrorCode::ALL`] (`R70`).
#[must_use]
pub fn problem_catalog(base_uri: &str) -> Vec<ProblemCatalogEntry> {
    ErrorCode::ALL
        .iter()
        .map(|&ec| {
            let code = http_code(ec);
            ProblemCatalogEntry {
                catalog_code: ec.as_str(),
                code,
                status: http_status(ec),
                problem_type: problem_type(base_uri, code),
                detail_is_public: detail_is_public(ec),
            }
        })
        .collect()
}

/// Sealed-style adapter trait converting core error types into [`WebError`] (`R70`).
pub trait ProblemSource {
    /// Convert this error into a [`WebError`] anchored at `base_uri` and optional `instance` path.
    fn to_web_error(&self, base_uri: &str, instance: Option<&str>) -> WebError;
}

impl ProblemSource for DomainError {
    fn to_web_error(&self, base_uri: &str, instance: Option<&str>) -> WebError {
        WebError::from_domain(self, base_uri, instance)
    }
}

#[derive(Debug, Clone)]
struct WebErrorInner {
    status: StatusCode,
    code: String,
    catalog_code: &'static str,
    title: String,
    detail: Option<String>,
    log_detail: Option<String>,
    instance: Option<String>,
    base_uri: String,
    documentation: Option<String>,
    errors: Vec<FieldError>,
    diagnostics: Option<Diagnostics>,
    headers: HeaderMap,
}

/// Unified HTTP error response type rendered exclusively as RFC 9457 `application/problem+json`
/// (`R70`).
///
/// Boxed internally so `Result<T, WebError>` remains pointer-sized on happy paths.
#[derive(Debug, Clone)]
pub struct WebError(Box<WebErrorInner>);

impl WebError {
    /// Build a [`WebError`] from a core [`DomainError`], redacting detail whenever
    /// [`detail_is_public`] is `false` (`R70` `W5`).
    #[must_use]
    pub fn from_domain(err: &DomainError, base_uri: &str, instance: Option<&str>) -> Self {
        let ec = err.error_code();
        let status = http_status(ec);
        let code = http_code(ec);
        let raw_msg = err.to_string();
        let (public_detail, log_detail) = if detail_is_public(ec) {
            (Some(raw_msg.clone()), Some(raw_msg))
        } else {
            (Some(default_safe_detail(status).to_owned()), Some(raw_msg))
        };

        Self(Box::new(WebErrorInner {
            status,
            code: code.to_owned(),
            catalog_code: ec.as_str(),
            title: status_title(status).to_owned(),
            detail: public_detail,
            log_detail,
            instance: instance.map(sanitize_instance),
            base_uri: base_uri.to_owned(),
            documentation: None,
            errors: Vec::new(),
            diagnostics: None,
            headers: HeaderMap::new(),
        }))
    }

    /// Construct a framework-originated [`WebError`] (400, 404, 405, 408, 409, 413, 415, 422, 429,
    /// 500, 503).
    #[must_use]
    pub fn framework(
        status: StatusCode,
        code: impl Into<String>,
        catalog_code: ErrorCode,
        detail: impl Into<String>,
        base_uri: &str,
        instance: Option<&str>,
    ) -> Self {
        Self(Box::new(WebErrorInner {
            status,
            code: code.into(),
            catalog_code: catalog_code.as_str(),
            title: status_title(status).to_owned(),
            detail: Some(detail.into()),
            log_detail: None,
            instance: instance.map(sanitize_instance),
            base_uri: base_uri.to_owned(),
            documentation: None,
            errors: Vec::new(),
            diagnostics: None,
            headers: HeaderMap::new(),
        }))
    }

    /// Construct a `404 Not Found` problem response.
    #[must_use]
    pub fn not_found(base_uri: &str, instance: &str) -> Self {
        Self::framework(
            StatusCode::NOT_FOUND,
            "resource_not_found",
            ErrorCode::NotFound,
            "The requested endpoint does not exist.",
            base_uri,
            Some(instance),
        )
    }

    /// Construct a `405 Method Not Allowed` problem response.
    #[must_use]
    pub fn method_not_allowed(base_uri: &str, instance: &str) -> Self {
        Self::framework(
            StatusCode::METHOD_NOT_ALLOWED,
            "method_not_allowed",
            ErrorCode::Usage,
            "The HTTP method is not allowed for this resource.",
            base_uri,
            Some(instance),
        )
    }

    /// Construct a `429 Too Many Requests` problem response (`R74`).
    #[must_use]
    pub fn rate_limited(base_uri: &str, instance: &str) -> Self {
        Self::framework(
            StatusCode::TOO_MANY_REQUESTS,
            "rate_limit_exceeded",
            ErrorCode::Usage,
            "Request rate limit exceeded; retry after the interval indicated in Retry-After.",
            base_uri,
            Some(instance),
        )
    }

    /// Construct a `503 Service Unavailable` problem response (`R73`, `R80`).
    #[must_use]
    pub fn service_unavailable(base_uri: &str, instance: &str, detail: impl Into<String>) -> Self {
        Self::framework(
            StatusCode::SERVICE_UNAVAILABLE,
            "service_unavailable",
            ErrorCode::Io,
            detail,
            base_uri,
            Some(instance),
        )
    }

    /// Construct a redacted `500 Internal Server Error` problem response.
    #[must_use]
    pub fn internal(base_uri: &str, instance: Option<&str>) -> Self {
        Self::framework(
            StatusCode::INTERNAL_SERVER_ERROR,
            "internal_error",
            ErrorCode::Unexpected,
            "An internal server error occurred.",
            base_uri,
            instance,
        )
    }

    /// Attach an extra HTTP response header (e.g. `WWW-Authenticate`, `Retry-After`,
    /// `Cache-Control`).
    #[must_use]
    pub fn with_header(mut self, name: HeaderName, value: HeaderValue) -> Self {
        self.0.headers.insert(name, value);
        self
    }

    /// Override the RFC 9457 `instance` path (query fragments are stripped automatically).
    #[must_use]
    pub fn with_instance(mut self, instance: impl AsRef<str>) -> Self {
        self.0.instance = Some(sanitize_instance(instance.as_ref()));
        self
    }

    /// Attach an optional HTTPS `documentation` URI extension member (`R5.13.4`).
    #[must_use]
    pub fn with_documentation(mut self, uri: impl Into<String>) -> Self {
        self.0.documentation = Some(uri.into());
        self
    }

    /// Attach structured field validation errors (`R5.15`).
    #[must_use]
    pub fn with_errors(mut self, errors: Vec<FieldError>) -> Self {
        self.0.errors = errors;
        self
    }

    /// Attach redacted readiness diagnostics (`R70` rev 5, `R80`).
    #[must_use]
    pub fn with_diagnostics(mut self, diagnostics: Diagnostics) -> Self {
        self.0.diagnostics = Some(diagnostics);
        self
    }

    /// Override the RFC 9457 `type` base URI.
    #[must_use]
    pub fn with_base_uri(mut self, base_uri: impl Into<String>) -> Self {
        self.0.base_uri = base_uri.into();
        self
    }

    /// Return the internal diagnostic message retained for server-side logging (never serialized
    /// onto `5xx` wire responses).
    #[must_use]
    pub fn log_detail(&self) -> Option<&str> {
        self.0.log_detail.as_deref()
    }

    /// Return the HTTP status code.
    #[must_use]
    pub const fn status(&self) -> StatusCode {
        self.0.status
    }

    /// Return the lowercase snake_case HTTP error code.
    #[must_use]
    pub fn code(&self) -> &str {
        &self.0.code
    }

    /// Return the `RSLB###` catalog code.
    #[must_use]
    pub const fn catalog_code(&self) -> &'static str {
        self.0.catalog_code
    }
}

impl fmt::Display for WebError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{} {} ({})",
            self.0.status.as_u16(),
            self.0.code,
            self.0.catalog_code
        )
    }
}

impl IntoResponse for WebError {
    fn into_response(self) -> Response {
        let inner = *self.0;
        let ext = ProblemExt {
            code: inner.code.clone(),
            catalog_code: inner.catalog_code.to_owned(),
            documentation: inner.documentation,
            errors: inner.errors,
            diagnostics: inner.diagnostics,
        };

        let mut problem = ProblemDetails::new()
            .with_status(inner.status)
            .with_title(inner.title);

        let type_str = problem_type(&inner.base_uri, &inner.code);
        if let Ok(uri) = Uri::try_from(type_str.as_str()) {
            problem = problem.with_type(uri);
        }
        if let Some(detail) = inner.detail {
            problem = problem.with_detail(detail);
        }
        if let Some(inst) = inner.instance
            && let Ok(uri) = Uri::try_from(inst.as_str())
        {
            problem = problem.with_instance(uri);
        }

        let mut response = problem.with_extensions(ext).into_response();

        // Ensure Content-Type is exact RFC 9457 `application/problem+json`.
        response.headers_mut().insert(
            header::CONTENT_TYPE,
            HeaderValue::from_static(PROBLEM_CONTENT_TYPE),
        );

        let has_custom_cache = inner.headers.contains_key(header::CACHE_CONTROL);
        for (name, value) in &inner.headers {
            response.headers_mut().insert(name, value.clone());
        }
        if !has_custom_cache {
            response
                .headers_mut()
                .insert(header::CACHE_CONTROL, HeaderValue::from_static("no-store"));
        }

        response
    }
}

fn sanitize_instance(raw: &str) -> String {
    let path_only = raw.split('?').next().unwrap_or("/");
    if path_only.is_empty() {
        "/".to_owned()
    } else {
        path_only.to_owned()
    }
}

fn status_title(status: StatusCode) -> &'static str {
    status.canonical_reason().unwrap_or("Error")
}

fn default_safe_detail(status: StatusCode) -> &'static str {
    match status {
        StatusCode::UNAUTHORIZED => "Authentication credentials were rejected.",
        StatusCode::BAD_GATEWAY => "An upstream service failed to fulfill the request.",
        StatusCode::SERVICE_UNAVAILABLE => "The service is temporarily unavailable.",
        _ => "An internal server error occurred.",
    }
}

/// Convert a [`tokio::task::spawn_blocking`] [`JoinError`] into a redacted `500` [`WebError`]
/// without exposing panic payloads (`R70` R14, `R05`).
#[must_use]
pub fn join_error_to_web_error(err: JoinError, base_uri: &str, instance: &str) -> WebError {
    if err.is_panic() {
        tracing::error!(instance, "blocking service task panicked");
    } else {
        tracing::error!(instance, "blocking service task cancelled");
    }
    WebError::internal(base_uri, Some(instance))
}

/// Router fallback converting unmatched routes into RFC 9457 `404` (`R70`, `R79`).
pub async fn not_found(
    axum::extract::State(settings): axum::extract::State<WebSettings>,
    uri: Uri,
) -> WebError {
    #[cfg(feature = "metrics")]
    crate::metrics::count_unmatched();
    WebError::not_found(&settings.problem_base_uri, uri.path())
}

/// Router `method_not_allowed_fallback` converting unsupported HTTP methods into RFC 9457 `405`
/// while preserving Axum's `Allow` header (`R70`).
pub async fn method_not_allowed(
    axum::extract::State(settings): axum::extract::State<WebSettings>,
    uri: Uri,
) -> WebError {
    WebError::method_not_allowed(&settings.problem_base_uri, uri.path())
}

/// JSON request body extractor mapping Axum rejections to RFC 9457 `400`/`413`/`415`/`422`
/// without ever echoing caller input values (`R70` M-4, R8.12).
#[derive(Debug, Clone, Copy)]
pub struct ProblemJson<T>(pub T);

impl<S, T> FromRequest<S> for ProblemJson<T>
where
    S: Send + Sync,
    WebSettings: FromRef<S>,
    T: DeserializeOwned,
{
    type Rejection = WebError;

    async fn from_request(req: Request, state: &S) -> Result<Self, Self::Rejection> {
        let settings = WebSettings::from_ref(state);
        let path = req.uri().path().to_owned();
        match Json::<T>::from_request(req, state).await {
            Ok(Json(value)) => Ok(Self(value)),
            Err(JsonRejection::MissingJsonContentType(_)) => Err(WebError::framework(
                StatusCode::UNSUPPORTED_MEDIA_TYPE,
                "unsupported_media_type",
                ErrorCode::Usage,
                "Request Content-Type must be application/json.",
                &settings.problem_base_uri,
                Some(&path),
            )),
            Err(JsonRejection::JsonSyntaxError(_)) => Err(WebError::framework(
                StatusCode::BAD_REQUEST,
                "invalid_json",
                ErrorCode::Usage,
                "Request body is not valid JSON.",
                &settings.problem_base_uri,
                Some(&path),
            )),
            Err(JsonRejection::JsonDataError(err)) => {
                let pointer = extract_safe_field_pointer(&err.body_text());
                Err(WebError::framework(
                    StatusCode::UNPROCESSABLE_ENTITY,
                    "validation_failed",
                    ErrorCode::Usage,
                    "Request body failed schema validation.",
                    &settings.problem_base_uri,
                    Some(&path),
                )
                .with_errors(vec![FieldError {
                    pointer,
                    code: "invalid_field".to_owned(),
                    detail: "Field is missing or has an invalid type.".to_owned(),
                }]))
            }
            Err(_) => Err(WebError::framework(
                StatusCode::BAD_REQUEST,
                "invalid_request",
                ErrorCode::Usage,
                "Request body could not be read or parsed.",
                &settings.problem_base_uri,
                Some(&path),
            )),
        }
    }
}

/// Extract a safe RFC 6901 field pointer when serde reports a missing/unknown field name,
/// strictly validating identifier characters so caller values are never echoed (`R70` M-4).
fn extract_safe_field_pointer(raw: &str) -> String {
    for marker in ["missing field `", "unknown field `"] {
        if let Some(after) = raw.split(marker).nth(1)
            && let Some(field) = after.split('`').next()
            && !field.is_empty()
            && field.len() <= 64
            && field
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')
        {
            return format!("/{field}");
        }
    }
    "/".to_owned()
}

/// Path extractor converting Axum [`PathRejection`] to RFC 9457 `400` without echoing input (`R70`).
#[derive(Debug, Clone, Copy)]
pub struct ProblemPath<T>(pub T);

impl<S, T> FromRequestParts<S> for ProblemPath<T>
where
    S: Send + Sync,
    WebSettings: FromRef<S>,
    T: DeserializeOwned + Send,
{
    type Rejection = WebError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let settings = WebSettings::from_ref(state);
        let path = parts.uri.path().to_owned();
        match Path::<T>::from_request_parts(parts, state).await {
            Ok(Path(val)) => Ok(Self(val)),
            Err(PathRejection::MissingPathParams(_)) => {
                Err(WebError::internal(&settings.problem_base_uri, Some(&path)))
            }
            Err(_) => Err(WebError::framework(
                StatusCode::BAD_REQUEST,
                "invalid_path_parameter",
                ErrorCode::Usage,
                "One or more path parameters are invalid.",
                &settings.problem_base_uri,
                Some(&path),
            )),
        }
    }
}

/// Query extractor converting Axum [`QueryRejection`] to RFC 9457 `400` without echoing input (`R70`).
#[derive(Debug, Clone, Copy)]
pub struct ProblemQuery<T>(pub T);

impl<S, T> FromRequestParts<S> for ProblemQuery<T>
where
    S: Send + Sync,
    WebSettings: FromRef<S>,
    T: DeserializeOwned + Send,
{
    type Rejection = WebError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let settings = WebSettings::from_ref(state);
        let path = parts.uri.path().to_owned();
        match Query::<T>::from_request_parts(parts, state).await {
            Ok(Query(val)) => Ok(Self(val)),
            Err(QueryRejection::FailedToDeserializeQueryString(_)) | Err(_) => {
                Err(WebError::framework(
                    StatusCode::BAD_REQUEST,
                    "invalid_query_parameter",
                    ErrorCode::Usage,
                    "One or more query parameters are malformed.",
                    &settings.problem_base_uri,
                    Some(&path),
                ))
            }
        }
    }
}

/// Decode a single URL-encoded query component (`%XX` and `+`).
pub(crate) fn percent_decode(raw: &str) -> Option<String> {
    let bytes = raw.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'+' => {
                out.push(b' ');
                i += 1;
            }
            b'%' => {
                if i + 2 >= bytes.len() {
                    return None;
                }
                let hi = hex_nibble(bytes[i + 1])?;
                let lo = hex_nibble(bytes[i + 2])?;
                out.push((hi << 4) | lo);
                i += 3;
            }
            b => {
                out.push(b);
                i += 1;
            }
        }
    }
    String::from_utf8(out).ok()
}

const fn hex_nibble(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

/// Parse raw URI query string into decoded `(key, value_option)` pairs.
pub(crate) fn parse_query_pairs(query: &str) -> Result<Vec<(String, Option<String>)>, ()> {
    if query.is_empty() {
        return Ok(Vec::new());
    }
    let mut pairs = Vec::new();
    for segment in query.split('&') {
        if segment.is_empty() {
            continue;
        }
        if let Some((raw_k, raw_v)) = segment.split_once('=') {
            let k = percent_decode(raw_k).ok_or(())?;
            let v = percent_decode(raw_v).ok_or(())?;
            pairs.push((k, Some(v)));
        } else {
            let k = percent_decode(segment).ok_or(())?;
            pairs.push((k, None));
        }
    }
    Ok(pairs)
}

/// Reject reserved query parameters (`stream`, and `dry_run` on mutating endpoints that do not
/// support dry-run) with RFC 9457 `400 Bad Request` (`R1.9`, `R13.3`, `R70`).
pub(crate) fn reject_unsupported_query_params(
    uri: &Uri,
    base_uri: &str,
    reject_dry_run: bool,
) -> Result<(), WebError> {
    let Some(raw_q) = uri.query() else {
        return Ok(());
    };
    let pairs = parse_query_pairs(raw_q).map_err(|()| {
        WebError::framework(
            StatusCode::BAD_REQUEST,
            "invalid_query_parameter",
            ErrorCode::Usage,
            "Query string contains invalid percent-encoding.",
            base_uri,
            Some(uri.path()),
        )
    })?;
    for (k, _) in pairs {
        if k == "stream" {
            return Err(WebError::framework(
                StatusCode::BAD_REQUEST,
                "streaming_not_supported",
                ErrorCode::Usage,
                "The 'stream' query parameter is not supported on this endpoint.",
                base_uri,
                Some(uri.path()),
            ));
        }
        if reject_dry_run && k == "dry_run" {
            return Err(WebError::framework(
                StatusCode::BAD_REQUEST,
                "dry_run_not_supported",
                ErrorCode::Usage,
                "The 'dry_run' query parameter is not supported on this endpoint.",
                base_uri,
                Some(uri.path()),
            ));
        }
    }
    Ok(())
}
