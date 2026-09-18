#!/usr/bin/env bash
# R70 — re-run of the acceptance criteria raw/opus.md reports as executed.
#
# This builds a THROWAWAY two-crate probe under $TMPDIR to check whether the
# report's claims hold; it does not implement the template.  Nothing it writes
# survives the run.  The probe mirrors R02's accepted topology (a core crate
# holding a stand-in for R67's catalog, a web crate holding the envelope) at
# R69 revision 10's pinned versions.
#
# Every check asserts on CONTENT.  PASS/FAIL/SKIP are counted and summed and a
# FAIL exits non-zero.
set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf 'SKIP  %s\n' "$1"; }
assert() { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }
# contains <label> <file> <literal>
contains() {
  if $GREP -qF -- "$3" "$2"; then ok "$1"; else bad "$1 — not found: $3"; fi
}
# lacks <label> <file> <literal>
lacks() {
  if $GREP -qF -- "$3" "$2"; then bad "$1 — present but must not be: $3"; else ok "$1"; fi
}

MSRV=1.96.0          # stable minus 2 minors, re-derived in registry.sh
scratch="$(mktemp -d "${TMPDIR:-/tmp}/r70-probe.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
export CARGO_TARGET_DIR="$scratch/target"

printf '=== R70 probe: acceptance criteria re-run ===\n'
printf 'date (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'os: %s %s (%s)\n' "$(sw_vers -productName 2>/dev/null || uname -s)" \
  "$(sw_vers -productVersion 2>/dev/null || uname -r)" "$(uname -m)"
printf 'host rustc: %s\n' "$(rustc --version)"
printf 'host cargo: %s\n' "$(cargo --version)"
printf 'grep: %s\n' "$($GREP --version | head -1)"
if command -v rustup >/dev/null 2>&1 && rustup toolchain list | $GREP -q "^${MSRV}-"; then
  MSRV_AVAILABLE=yes
  printf 'MSRV toolchain: %s\n' "$(rustup run "$MSRV" rustc --version)"
else
  MSRV_AVAILABLE=no
  printf 'MSRV toolchain: %s NOT installed\n' "$MSRV"
fi
printf 'scratch: %s (deleted on exit)\n\n' "$scratch"

W="$scratch/probe"
mkdir -p "$W/r70core/src" "$W/r70web/src" "$W/r70web/tests" "$W/r70ctl/src"

############################################################
# Workspace manifests — R69 revision 10's pinned versions.
############################################################
cat > "$W/Cargo.toml" <<'EOF'
[workspace]
members = ["r70core", "r70web", "r70ctl"]
resolver = "3"
EOF

cat > "$W/r70core/Cargo.toml" <<'EOF'
[package]
name = "r70core"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[dependencies]
EOF

cat > "$W/r70web/Cargo.toml" <<'EOF'
[package]
name = "r70web"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[dependencies]
r70core = { path = "../r70core" }
axum = "=0.8.9"
problem_details = { version = "=0.10.0", features = ["axum", "json"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }

[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }

[[example]]
name = "dump"
path = "examples/dump.rs"
EOF

# The control member: identical dependencies MINUS problem_details.  Diffing the
# two resolved trees is what proves "exactly one crate added".
cat > "$W/r70ctl/Cargo.toml" <<'EOF'
[package]
name = "r70ctl"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[dependencies]
r70core = { path = "../r70core" }
axum = "=0.8.9"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
EOF

cat > "$W/r70ctl/src/lib.rs" <<'EOF'
//! Control member: the same dependency set without `problem_details`.
pub fn touch() -> &'static str {
    let _ = axum::http::StatusCode::OK;
    "ctl"
}
EOF

############################################################
# r70core — a stand-in for R67's published catalog (17 rows) and a domain error.
############################################################
cat > "$W/r70core/src/lib.rs" <<'EOF'
//! Stand-in for R67 `error-contract/v1`: the catalog enum, `ALL`, `as_str`, and
//! a domain error reached through R03's `Result<Option<T>, PortError>` port.
//! This is a PROBE, not the template.
#![forbid(unsafe_code)]

/// R67's catalog.  `#[non_exhaustive]` exactly as R67 specifies, so a match in
/// another crate cannot be exhaustive.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum ErrorCode {
    Unexpected,
    Io,
    Transport,
    RemoteApi,
    ConfigLayerUnreadable,
    UsageParse,
    ConfigUnparsable,
    ConfigValueInvalid,
    SecretChannel,
    InputUnavailable,
    NotFound,
    CredentialsAbsent,
    CredentialsRejected,
    Conflict,
    Sigint,
    Sigterm,
    PromptInterrupted,
}

impl ErrorCode {
    /// R67's compensation for `#[non_exhaustive]`: the list a consumer's
    /// coverage test iterates.
    pub const ALL: &'static [ErrorCode] = &[
        ErrorCode::Unexpected,
        ErrorCode::Io,
        ErrorCode::Transport,
        ErrorCode::RemoteApi,
        ErrorCode::ConfigLayerUnreadable,
        ErrorCode::UsageParse,
        ErrorCode::ConfigUnparsable,
        ErrorCode::ConfigValueInvalid,
        ErrorCode::SecretChannel,
        ErrorCode::InputUnavailable,
        ErrorCode::NotFound,
        ErrorCode::CredentialsAbsent,
        ErrorCode::CredentialsRejected,
        ErrorCode::Conflict,
        ErrorCode::Sigint,
        ErrorCode::Sigterm,
        ErrorCode::PromptInterrupted,
    ];

    /// R67: an explicit `const fn` match, never derived from a variant name.
    pub const fn as_str(&self) -> &'static str {
        match self {
            ErrorCode::Unexpected => "RSLB000",
            ErrorCode::Io => "RSLB101",
            ErrorCode::Transport => "RSLB102",
            ErrorCode::RemoteApi => "RSLB103",
            ErrorCode::ConfigLayerUnreadable => "RSLB104",
            ErrorCode::UsageParse => "RSLB201",
            ErrorCode::ConfigUnparsable => "RSLB202",
            ErrorCode::ConfigValueInvalid => "RSLB203",
            ErrorCode::SecretChannel => "RSLB204",
            ErrorCode::InputUnavailable => "RSLB205",
            ErrorCode::NotFound => "RSLB301",
            ErrorCode::CredentialsAbsent => "RSLB401",
            ErrorCode::CredentialsRejected => "RSLB402",
            ErrorCode::Conflict => "RSLB501",
            ErrorCode::Sigint => "RSLB901",
            ErrorCode::Sigterm => "RSLB902",
            ErrorCode::PromptInterrupted => "RSLB903",
        }
    }
}

/// The library crate's own error type.
#[derive(Debug)]
pub enum DomainError {
    NotFound { what: String },
    Upstream { detail: String },
    Conflict { detail: String },
    CredentialsRejected,
}

impl DomainError {
    pub fn code(&self) -> ErrorCode {
        match self {
            DomainError::NotFound { .. } => ErrorCode::NotFound,
            DomainError::Upstream { .. } => ErrorCode::RemoteApi,
            DomainError::Conflict { .. } => ErrorCode::Conflict,
            DomainError::CredentialsRejected => ErrorCode::CredentialsRejected,
        }
    }

    pub fn message(&self) -> String {
        match self {
            DomainError::NotFound { what } => format!("project '{what}' not found"),
            DomainError::Upstream { detail } => detail.clone(),
            DomainError::Conflict { detail } => detail.clone(),
            DomainError::CredentialsRejected => "credentials rejected".to_string(),
        }
    }
}

/// R03's port shape: absence is `Ok(None)`, failure is `Err`.
pub fn find_project(name: &str) -> Result<Option<String>, DomainError> {
    match name {
        "known" => Ok(Some("known".to_string())),
        "upstream" => Err(DomainError::Upstream {
            detail: "GET https://api.example.com/x?token=s3cret failed: 500".to_string(),
        }),
        _ => Ok(None),
    }
}
EOF

############################################################
# r70web/src/problems.rs — the envelope, the status table, the funnel.
############################################################
cat > "$W/r70web/src/problems.rs" <<'EOF'
//! The RFC 9457 envelope, the domain-code-to-status table, and the funnel.
#![allow(clippy::needless_pass_by_value)]

use std::collections::BTreeMap;

use axum::extract::rejection::{JsonRejection, PathRejection, QueryRejection};
use axum::extract::{FromRequest, FromRequestParts, Request};
use axum::http::request::Parts;
use axum::http::{HeaderName, HeaderValue, StatusCode, Uri};
use axum::response::{IntoResponse, Response};
use problem_details::ProblemDetails;
use r70core::{DomainError, ErrorCode};
use serde::Serialize;

/// The substitute text used whenever W5 withholds the real detail.
pub const WITHHELD_DETAIL: &str = "An unexpected error occurred.";

/// RFC 9457 3.2 extension members carried on every envelope.
#[derive(Debug, Clone, Default, Serialize)]
pub struct ProblemExt {
    /// R67's catalog token.  Always present.
    pub code: &'static str,
    /// Field-level report; omitted when absent.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub errors: Option<BTreeMap<String, Vec<String>>>,
}

/// The one envelope type.
pub type Problem = ProblemDetails<ProblemExt>;

/// W4: the whole domain-to-status table, in one reviewable place.
///
/// The `_` arm is required and reachable because `ErrorCode` is
/// `#[non_exhaustive]` and lives in another crate; `ErrorCode::ALL` plus the
/// coverage test is what makes the table total.
pub const fn http_status(code: ErrorCode) -> StatusCode {
    match code {
        ErrorCode::NotFound => StatusCode::NOT_FOUND,
        ErrorCode::CredentialsAbsent | ErrorCode::CredentialsRejected => StatusCode::UNAUTHORIZED,
        ErrorCode::Conflict => StatusCode::CONFLICT,
        // A domain-raised RSLB201 means the caller's input was unusable; a
        // FRAMEWORK-raised one keeps axum's own status through `framework()`.
        ErrorCode::UsageParse => StatusCode::BAD_REQUEST,
        ErrorCode::Transport | ErrorCode::RemoteApi => StatusCode::BAD_GATEWAY,
        ErrorCode::Unexpected
        | ErrorCode::Io
        | ErrorCode::ConfigLayerUnreadable
        | ErrorCode::ConfigUnparsable
        | ErrorCode::ConfigValueInvalid
        | ErrorCode::SecretChannel => StatusCode::INTERNAL_SERVER_ERROR,
        ErrorCode::InputUnavailable
        | ErrorCode::Sigint
        | ErrorCode::Sigterm
        | ErrorCode::PromptInterrupted => StatusCode::INTERNAL_SERVER_ERROR,
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

/// The codes no HTTP request can raise; they get a row so the table is total.
pub const NOT_REQUEST_REACHABLE: &[ErrorCode] = &[
    ErrorCode::InputUnavailable,
    ErrorCode::Sigint,
    ErrorCode::Sigterm,
    ErrorCode::PromptInterrupted,
];

/// W5: whether this code's own message may reach a client.
pub const fn detail_is_public(code: ErrorCode) -> bool {
    matches!(
        code,
        ErrorCode::NotFound | ErrorCode::Conflict | ErrorCode::UsageParse
    )
}

/// The seam the report claims lets this design be wired to any error type.
pub trait ProblemSource {
    fn error_code(&self) -> ErrorCode;
    fn detail(&self) -> Option<String> {
        None
    }
    fn field_errors(&self) -> Option<BTreeMap<String, Vec<String>>> {
        None
    }
}

impl ProblemSource for DomainError {
    fn error_code(&self) -> ErrorCode {
        self.code()
    }
    fn detail(&self) -> Option<String> {
        Some(self.message())
    }
}

/// The one error type a handler returns.
#[derive(Debug)]
pub struct WebError {
    code: ErrorCode,
    status: StatusCode,
    detail: Option<String>,
    errors: Option<BTreeMap<String, Vec<String>>>,
    instance: Option<String>,
    headers: Vec<(HeaderName, HeaderValue)>,
    logged: Option<String>,
}

impl WebError {
    /// A domain failure: the status comes from the table.
    pub fn new(code: ErrorCode) -> Self {
        Self {
            code,
            status: http_status(code),
            detail: None,
            errors: None,
            instance: None,
            headers: Vec::new(),
            logged: None,
        }
    }

    /// A framework failure: the status is the one the framework computed, the
    /// identity is still a catalog token.
    pub fn framework(status: StatusCode, code: ErrorCode) -> Self {
        Self {
            status,
            ..Self::new(code)
        }
    }

    pub fn from_source<S: ProblemSource>(source: &S) -> Self {
        let code = source.error_code();
        let mut error = Self::new(code);
        if let Some(detail) = source.detail() {
            error.logged = Some(detail.clone());
            error.detail = Some(detail);
        }
        error.errors = source.field_errors();
        error
    }

    #[must_use]
    pub fn with_detail(mut self, detail: impl Into<String>) -> Self {
        let detail = detail.into();
        self.logged = Some(detail.clone());
        self.detail = Some(detail);
        self
    }

    #[must_use]
    pub fn with_errors(mut self, errors: BTreeMap<String, Vec<String>>) -> Self {
        self.errors = Some(errors);
        self
    }

    #[must_use]
    pub fn with_instance(mut self, instance: impl Into<String>) -> Self {
        self.instance = Some(instance.into());
        self
    }

    #[must_use]
    pub fn with_header(mut self, name: HeaderName, value: HeaderValue) -> Self {
        self.headers.push((name, value));
        self
    }

    /// The full text, for the log, whether or not the client may see it.
    pub fn log_detail(&self) -> Option<&str> {
        self.logged.as_deref()
    }

    pub fn code(&self) -> ErrorCode {
        self.code
    }

    pub fn to_problem(&self) -> Problem {
        let extensions = ProblemExt {
            code: self.code.as_str(),
            errors: self.errors.clone(),
        };
        let mut problem = ProblemDetails::from_status_code(self.status).with_extensions(extensions);
        let detail = if detail_is_public(self.code) {
            self.detail.clone()
        } else {
            Some(WITHHELD_DETAIL.to_string())
        };
        if let Some(detail) = detail {
            problem = problem.with_detail(detail);
        }
        if let Some(instance) = &self.instance
            && let Ok(uri) = instance.parse::<Uri>()
        {
            problem = problem.with_instance(uri);
        }
        problem
    }
}

impl IntoResponse for WebError {
    fn into_response(self) -> Response {
        let mut response = self.to_problem().into_response();
        for (name, value) in self.headers {
            response.headers_mut().insert(name, value);
        }
        response
    }
}

fn field_report(field: &str, message: String) -> BTreeMap<String, Vec<String>> {
    let mut errors = BTreeMap::new();
    errors.insert(field.to_string(), vec![message]);
    errors
}

impl From<JsonRejection> for WebError {
    fn from(rejection: JsonRejection) -> Self {
        let status = rejection.status();
        let text = rejection.body_text();
        WebError::framework(status, ErrorCode::UsageParse)
            .with_detail("Request validation failed.")
            .with_errors(field_report("body", text))
    }
}

impl From<PathRejection> for WebError {
    fn from(rejection: PathRejection) -> Self {
        let status = rejection.status();
        let text = rejection.body_text();
        WebError::framework(status, ErrorCode::UsageParse)
            .with_detail("Request validation failed.")
            .with_errors(field_report("path", text))
    }
}

impl From<QueryRejection> for WebError {
    fn from(rejection: QueryRejection) -> Self {
        let status = rejection.status();
        let text = rejection.body_text();
        WebError::framework(status, ErrorCode::UsageParse)
            .with_detail("Request validation failed.")
            .with_errors(field_report("query", text))
    }
}

/// The hook that reshapes the framework's own rejection body.
pub struct ProblemJson<T>(pub T);

impl<T, S> FromRequest<S> for ProblemJson<T>
where
    axum::Json<T>: FromRequest<S, Rejection = JsonRejection>,
    S: Send + Sync,
{
    type Rejection = WebError;

    async fn from_request(req: Request, state: &S) -> Result<Self, Self::Rejection> {
        let axum::Json(value) = axum::Json::<T>::from_request(req, state).await?;
        Ok(ProblemJson(value))
    }
}

pub struct ProblemPath<T>(pub T);

impl<T, S> FromRequestParts<S> for ProblemPath<T>
where
    axum::extract::Path<T>: FromRequestParts<S, Rejection = PathRejection>,
    S: Send + Sync,
{
    type Rejection = WebError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let axum::extract::Path(value) =
            axum::extract::Path::<T>::from_request_parts(parts, state).await?;
        Ok(ProblemPath(value))
    }
}

pub struct ProblemQuery<T>(pub T);

impl<T, S> FromRequestParts<S> for ProblemQuery<T>
where
    axum::extract::Query<T>: FromRequestParts<S, Rejection = QueryRejection>,
    S: Send + Sync,
{
    type Rejection = WebError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let axum::extract::Query(value) =
            axum::extract::Query::<T>::from_request_parts(parts, state).await?;
        Ok(ProblemQuery(value))
    }
}

/// Router-level miss (404).
pub async fn not_found(uri: Uri) -> WebError {
    WebError::new(ErrorCode::NotFound)
        .with_detail("No route matches this path.")
        .with_instance(uri.path().to_string())
}

/// Matched path, wrong method (405).  axum has already set `Allow`.
pub async fn method_not_allowed() -> WebError {
    WebError::framework(StatusCode::METHOD_NOT_ALLOWED, ErrorCode::UsageParse)
        .with_detail("This method is not allowed for this path.")
}

/// R05's `spawn_blocking` bridge failing (panic or cancellation).
pub fn join_error_to_web_error(error: &tokio::task::JoinError) -> WebError {
    WebError::new(ErrorCode::Unexpected).with_detail(error.to_string())
}
EOF

############################################################
# r70web/src/lib.rs — the router and the handlers.
############################################################
cat > "$W/r70web/src/lib.rs" <<'EOF'
//! Probe web crate: the router that funnels every failure through `problems`.
#![forbid(unsafe_code)]

pub mod problems;

use axum::http::{HeaderValue, StatusCode, Uri, header};
use axum::response::Json;
use axum::routing::{get, post};
use axum::{Router, serve::Serve};
use r70core::{DomainError, ErrorCode, find_project};
use serde::{Deserialize, Serialize};

use problems::{ProblemJson, ProblemPath, WebError, join_error_to_web_error};

#[derive(Debug, Serialize)]
pub struct ProjectView {
    pub name: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct NewProject {
    pub name: String,
}

async fn get_project(ProblemPath(name): ProblemPath<String>, uri: Uri) -> Result<Json<ProjectView>, WebError> {
    // R03: absence is Ok(None); the use case turns it into the NotFound domain error.
    match find_project(&name) {
        Ok(Some(name)) => Ok(Json(ProjectView { name })),
        Ok(None) => Err(
            WebError::from_source(&DomainError::NotFound { what: name })
                .with_instance(uri.path().to_string()),
        ),
        Err(error) => Err(WebError::from_source(&error).with_instance(uri.path().to_string())),
    }
}

async fn create_project(ProblemJson(body): ProblemJson<NewProject>) -> Json<NewProject> {
    Json(body)
}

async fn upstream(uri: Uri) -> Result<Json<ProjectView>, WebError> {
    match find_project("upstream") {
        Ok(_) => Ok(Json(ProjectView { name: "x".into() })),
        // The domain message names an upstream URL and a token; W5 withholds it.
        Err(error) => Err(WebError::from_source(&error).with_instance(uri.path().to_string())),
    }
}

async fn count(ProblemPath(n): ProblemPath<u32>) -> Json<u32> {
    Json(n)
}

async fn blocking_panic() -> Result<Json<ProjectView>, WebError> {
    // R05's bridge: a synchronous core reached through spawn_blocking.
    let joined = tokio::task::spawn_blocking(|| -> String {
        panic!("boom inside the blocking bridge");
    })
    .await;
    match joined {
        Ok(name) => Ok(Json(ProjectView { name })),
        Err(error) => Err(join_error_to_web_error(&error)),
    }
}

async fn auth() -> Result<Json<ProjectView>, WebError> {
    Err(
        WebError::new(ErrorCode::CredentialsRejected).with_header(
            header::WWW_AUTHENTICATE,
            HeaderValue::from_static("Bearer realm=\"rslbp\""),
        ),
    )
}

async fn okay() -> &'static str {
    "ok"
}

pub fn build_router() -> Router {
    Router::new()
        .route("/projects/{name}", get(get_project))
        .route("/projects", post(create_project))
        .route("/upstream", get(upstream))
        .route("/count/{n}", get(count))
        .route("/panic", get(blocking_panic))
        .route("/auth", get(auth))
        .route("/ok", get(okay))
        .fallback(problems::not_found)
        .method_not_allowed_fallback(problems::method_not_allowed)
}

/// Only here to prove the router type composes with a real server binding.
pub fn _assert_serve_type(listener: tokio::net::TcpListener) -> Serve<tokio::net::TcpListener, Router, Router> {
    let _ = StatusCode::OK;
    axum::serve(listener, build_router())
}
EOF

mkdir -p "$W/r70web/examples"
cat > "$W/r70web/examples/dump.rs" <<'EOF'
//! Prints the four response bodies raw/opus.md captures, so they can be
//! compared literally rather than described.
use axum::body::Body;
use axum::http::{Method, Request, header};
use r70web::build_router;
use tower::ServiceExt;

async fn show(method: Method, path: &str, body: Body, content_type: Option<&str>) {
    let mut builder = Request::builder().method(method.clone()).uri(path);
    if let Some(value) = content_type {
        builder = builder.header(header::CONTENT_TYPE, value);
    }
    let request = builder.body(body).unwrap();
    let response = build_router().oneshot(request).await.unwrap();
    let status = response.status();
    let ctype = response
        .headers()
        .get(header::CONTENT_TYPE)
        .map(|v| v.to_str().unwrap().to_string())
        .unwrap_or_default();
    let bytes = axum::body::to_bytes(response.into_body(), 65536).await.unwrap();
    println!("{method} {path} -> {status} {ctype}");
    println!("{}", String::from_utf8(bytes.to_vec()).unwrap());
}

#[tokio::main]
async fn main() {
    show(Method::GET, "/projects/demo", Body::empty(), None).await;
    show(Method::GET, "/upstream", Body::empty(), None).await;
    show(
        Method::POST,
        "/projects",
        Body::from(r#"{"name": 42}"#),
        Some("application/json"),
    )
    .await;
    show(Method::DELETE, "/ok", Body::empty(), None).await;
}
EOF

############################################################
# r70web/tests/problems.rs — AC1..AC14 from raw/opus.md, plus two additions.
############################################################
cat > "$W/r70web/tests/problems.rs" <<'EOF'
use std::collections::BTreeMap;

use axum::body::Body;
use axum::http::{HeaderMap, Method, Request, StatusCode, header};
use r70core::ErrorCode;
use r70web::build_router;
use r70web::problems::{NOT_REQUEST_REACHABLE, detail_is_public, http_status};
use tower::ServiceExt;

const PROBLEM_JSON: &str = "application/problem+json";

async fn send(
    method: Method,
    path: &str,
    body: Body,
    content_type: Option<&str>,
) -> (StatusCode, HeaderMap, String) {
    let mut builder = Request::builder().method(method).uri(path);
    if let Some(value) = content_type {
        builder = builder.header(header::CONTENT_TYPE, value);
    }
    let response = build_router()
        .oneshot(builder.body(body).unwrap())
        .await
        .unwrap();
    let status = response.status();
    let headers = response.headers().clone();
    let bytes = axum::body::to_bytes(response.into_body(), 65536)
        .await
        .unwrap();
    (status, headers, String::from_utf8(bytes.to_vec()).unwrap())
}

fn content_type(headers: &HeaderMap) -> String {
    headers
        .get(header::CONTENT_TYPE)
        .map(|v| v.to_str().unwrap().to_string())
        .unwrap_or_default()
}

fn json(body: &str) -> BTreeMap<String, serde_json::Value> {
    serde_json::from_str(body).expect("response body is JSON")
}

// AC1 — every member of ErrorCode::ALL maps to a 4xx or a 5xx.
#[test]
fn ac1_status_table_is_total_over_all() {
    assert_eq!(ErrorCode::ALL.len(), 17, "catalog row count");
    for code in ErrorCode::ALL {
        let status = http_status(*code);
        assert!(
            status.is_client_error() || status.is_server_error(),
            "{} mapped to {status}",
            code.as_str()
        );
    }
}

// AC2 — every NOT_REQUEST_REACHABLE code is 500 and the list is its declared length.
#[test]
fn ac2_unreachable_codes_are_500() {
    assert_eq!(NOT_REQUEST_REACHABLE.len(), 4);
    for code in NOT_REQUEST_REACHABLE {
        assert_eq!(
            http_status(*code),
            StatusCode::INTERNAL_SERVER_ERROR,
            "{}",
            code.as_str()
        );
    }
}

// AC3 — no code whose status is 5xx is marked detail-public.
#[test]
fn ac3_no_server_error_leaks_its_detail() {
    for code in ErrorCode::ALL {
        if http_status(*code).is_server_error() {
            assert!(!detail_is_public(*code), "{} is 5xx and public", code.as_str());
        }
    }
}

// AC4 — a domain error renders 404 problem+json with code, title, detail,
// instance and NO errors member.
#[tokio::test]
async fn ac4_domain_error_envelope() {
    let (status, headers, body) = send(Method::GET, "/projects/demo", Body::empty(), None).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB301");
    assert_eq!(doc["title"], "Not Found");
    assert_eq!(doc["status"], 404);
    assert_eq!(doc["detail"], "project 'demo' not found");
    assert_eq!(doc["instance"], "/projects/demo");
    assert!(!doc.contains_key("errors"), "errors must be omitted");
    assert!(!doc.contains_key("type"), "type must be omitted");
}

// AC5 — py SEC-4: an upstream failure is 502 with the detail replaced and the
// upstream URL and token absent from the whole body.
#[tokio::test]
async fn ac5_upstream_detail_is_withheld() {
    let (status, headers, body) = send(Method::GET, "/upstream", Body::empty(), None).await;
    assert_eq!(status, StatusCode::BAD_GATEWAY);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB103");
    assert_eq!(doc["detail"], "An unexpected error occurred.");
    assert!(!body.contains("s3cret"), "token leaked: {body}");
    assert!(!body.contains("api.example.com"), "upstream host leaked: {body}");
}

// AC6 — Router::fallback renders the envelope with instance.
#[tokio::test]
async fn ac6_router_fallback_is_enveloped() {
    let (status, headers, body) = send(Method::GET, "/nope/at/all", Body::empty(), None).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB301");
    assert_eq!(doc["instance"], "/nope/at/all");
}

// AC7 — method_not_allowed_fallback renders the envelope at 405.
#[tokio::test]
async fn ac7_method_not_allowed_is_enveloped() {
    let (status, headers, body) = send(Method::DELETE, "/ok", Body::empty(), None).await;
    assert_eq!(status, StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB201");
    assert_eq!(doc["title"], "Method Not Allowed");
}

// AC8 — an extractor DATA error renders 422 with the field detail under errors.body.
#[tokio::test]
async fn ac8_json_data_error_is_422_with_errors() {
    let (status, headers, body) = send(
        Method::POST,
        "/projects",
        Body::from(r#"{"name": 42}"#),
        Some("application/json"),
    )
    .await;
    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB201");
    let errors = doc["errors"].as_object().expect("errors object");
    let messages = errors["body"].as_array().expect("errors.body array");
    assert!(
        messages[0].as_str().unwrap().contains("Failed to deserialize the JSON body"),
        "unexpected message: {messages:?}"
    );
}

// AC9 — a JSON SYNTAX error keeps axum's 400.
#[tokio::test]
async fn ac9_json_syntax_error_keeps_400() {
    let (status, headers, body) = send(
        Method::POST,
        "/projects",
        Body::from("{not json"),
        Some("application/json"),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert_eq!(json(&body)["code"], "RSLB201");
}

// AC10 — a missing content type keeps axum's 415.
#[tokio::test]
async fn ac10_missing_content_type_keeps_415() {
    let (status, headers, body) = send(
        Method::POST,
        "/projects",
        Body::from(r#"{"name":"x"}"#),
        None,
    )
    .await;
    assert_eq!(status, StatusCode::UNSUPPORTED_MEDIA_TYPE);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert_eq!(json(&body)["code"], "RSLB201");
}

// AC11 — a panic inside spawn_blocking becomes RSLB000/500, still enveloped,
// with the detail withheld.
#[tokio::test]
async fn ac11_spawn_blocking_panic_is_enveloped() {
    let (status, headers, body) = send(Method::GET, "/panic", Body::empty(), None).await;
    assert_eq!(status, StatusCode::INTERNAL_SERVER_ERROR);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB000");
    assert_eq!(doc["detail"], "An unexpected error occurred.");
    assert!(!body.contains("boom inside the blocking bridge"), "panic text leaked");
}

// AC12 — a 2xx response is untouched.
#[tokio::test]
async fn ac12_success_is_not_enveloped() {
    let (status, headers, body) = send(Method::GET, "/ok", Body::empty(), None).await;
    assert_eq!(status, StatusCode::OK);
    assert!(content_type(&headers).starts_with("text/plain"), "{}", content_type(&headers));
    assert_eq!(body, "ok");
}

// AC13 — RFC 9110 15.5.6: the 405 still carries Allow after the fallback
// replaced its body.
#[tokio::test]
async fn ac13_405_still_carries_allow() {
    let (status, headers, _) = send(Method::DELETE, "/ok", Body::empty(), None).await;
    assert_eq!(status, StatusCode::METHOD_NOT_ALLOWED);
    let allow = headers
        .get(header::ALLOW)
        .expect("RFC 9110 15.5.6 requires Allow on a 405")
        .to_str()
        .unwrap()
        .to_string();
    assert_eq!(allow, "GET,HEAD", "Allow header value");
}

// AC14 — RFC 9110 15.5.2: a 401 carries WWW-Authenticate AND the envelope.
#[tokio::test]
async fn ac14_401_carries_challenge_and_envelope() {
    let (status, headers, body) = send(Method::GET, "/auth", Body::empty(), None).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert_eq!(
        headers.get(header::WWW_AUTHENTICATE).unwrap().to_str().unwrap(),
        "Bearer realm=\"rslbp\""
    );
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB402");
    assert_eq!(doc["status"], 401);
}

// AC15 (addition, not in raw/opus.md) — a PATH rejection funnels too, proving
// the hook is per-extractor-family and not Json-specific.
#[tokio::test]
async fn ac15_path_rejection_is_enveloped() {
    let (status, headers, body) = send(Method::GET, "/count/abc", Body::empty(), None).await;
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert!(status.is_client_error(), "{status}");
    let doc = json(&body);
    assert_eq!(doc["code"], "RSLB201");
    assert!(doc["errors"].as_object().unwrap().contains_key("path"));
}

// AC16 (addition) — W3 as a walk: every failing request in this suite answers
// application/problem+json, and every 2xx does not.
#[tokio::test]
async fn ac16_every_non_2xx_is_problem_json() {
    let cases: Vec<(Method, &str, Body, Option<&str>)> = vec![
        (Method::GET, "/projects/demo", Body::empty(), None),
        (Method::GET, "/upstream", Body::empty(), None),
        (Method::GET, "/nope", Body::empty(), None),
        (Method::DELETE, "/ok", Body::empty(), None),
        (Method::POST, "/projects", Body::from(r#"{"name": 42}"#), Some("application/json")),
        (Method::POST, "/projects", Body::from("{nope"), Some("application/json")),
        (Method::POST, "/projects", Body::from(r#"{"name":"x"}"#), None),
        (Method::GET, "/panic", Body::empty(), None),
        (Method::GET, "/auth", Body::empty(), None),
        (Method::GET, "/count/abc", Body::empty(), None),
        (Method::GET, "/ok", Body::empty(), None),
        (Method::GET, "/projects/known", Body::empty(), None),
    ];
    let mut failures = 0;
    let mut successes = 0;
    for (method, path, body, ctype) in cases {
        let (status, headers, _) = send(method.clone(), path, body, ctype).await;
        if status.is_success() {
            successes += 1;
            assert_ne!(content_type(&headers), PROBLEM_JSON, "{method} {path}");
        } else {
            failures += 1;
            assert_eq!(content_type(&headers), PROBLEM_JSON, "{method} {path} -> {status}");
        }
    }
    assert_eq!((failures, successes), (10, 2), "walk coverage");
}
EOF

############################################################
printf -- '--- 1. build and test at the MSRV floor (%s)\n' "$MSRV"
############################################################
if [ "$MSRV_AVAILABLE" = yes ]; then
  if (cd "$W" && rustup run "$MSRV" cargo test --workspace) > "$scratch/msrv-test.log" 2>&1; then
    ok "cargo test --workspace compiled and ran under rustc $MSRV"
  else
    bad "cargo test --workspace FAILED under rustc $MSRV (see output below)"
    tail -40 "$scratch/msrv-test.log"
  fi
  contains "MSRV run: 16 integration tests passed" "$scratch/msrv-test.log" "16 passed; 0 failed"
  if $GREP -q "latest Rust 1.96 compatible versions" "$scratch/msrv-test.log"; then
    ok "cargo resolved the tree against Rust 1.96 ($($GREP -m1 'compatible versions' "$scratch/msrv-test.log" | sed 's/^ *//'))"
  else
    skip "resolver message absent (lockfile already present from an earlier step)"
  fi
else
  skip "MSRV compile at $MSRV: toolchain not installed on this host"
fi

############################################################
printf -- '\n--- 2. build and test on the host stable toolchain\n'
############################################################
if (cd "$W" && cargo test --workspace) > "$scratch/host-test.log" 2>&1; then
  ok "cargo test --workspace compiled and ran under the host toolchain"
else
  bad "cargo test --workspace FAILED under the host toolchain"
  tail -40 "$scratch/host-test.log"
fi
contains "host run: 16 integration tests passed" "$scratch/host-test.log" "16 passed; 0 failed"
lacks "host build emitted no warning" "$scratch/host-test.log" "warning:"

############################################################
printf -- '\n--- 3. the four response bodies raw/opus.md captures\n'
############################################################
if (cd "$W" && cargo run --quiet --example dump) > "$scratch/bodies.log" 2>"$scratch/bodies.err"; then
  ok "the dump example printed the four bodies"
  sed 's/^/      /' "$scratch/bodies.log"
else
  bad "the dump example failed"
  tail -20 "$scratch/bodies.err"
fi
contains "AC4 body verbatim" "$scratch/bodies.log" \
  '{"status":404,"title":"Not Found","detail":"project '"'"'demo'"'"' not found","instance":"/projects/demo","code":"RSLB301"}'
contains "AC5 body verbatim" "$scratch/bodies.log" \
  '{"status":502,"title":"Bad Gateway","detail":"An unexpected error occurred.","instance":"/upstream","code":"RSLB103"}'
contains "AC8 body carries errors.body" "$scratch/bodies.log" \
  '"code":"RSLB201","errors":{"body":["Failed to deserialize the JSON body into the target type'
contains "AC7 body verbatim" "$scratch/bodies.log" \
  '{"status":405,"title":"Method Not Allowed","detail":"This method is not allowed for this path.","code":"RSLB201"}'
lacks "no body carries a type member" "$scratch/bodies.log" '"type":'
lacks "no body carries a null" "$scratch/bodies.log" 'null'
contains "every problem body is application/problem+json" "$scratch/bodies.log" "application/problem+json"

############################################################
printf -- '\n--- 4. dependency cost: what problem_details actually adds\n'
############################################################
# `cargo tree` marks a subtree it has already printed with " (*)" and prints a
# workspace member with its path; normalise both away so the comparison is over
# package name and version only.
tree_of() {
  (cd "$W" && cargo tree -p "$1" --edges normal --prefix none) 2>/dev/null |
    sed -e 's/ (\*)$//' -e 's| (/.*)$||' | sort -u
}
tree_of r70web > "$scratch/tree-web.txt"
tree_of r70ctl > "$scratch/tree-ctl.txt"
added=$(comm -23 "$scratch/tree-web.txt" "$scratch/tree-ctl.txt" | $GREP -v '^r70web' | tr '\n' ' ' | sed 's/ $//')
assert "crates added to an axum+serde+tokio tree by problem_details" \
  "http-serde v2.1.1 problem_details v0.10.0" "$added"
contains "resolved axum version is R69's pin" "$scratch/tree-web.txt" "axum v0.8.9"
contains "resolved tokio version is R69's pin" "$scratch/tree-web.txt" "tokio v1.53.1"
contains "resolved problem_details version" "$scratch/tree-web.txt" "problem_details v0.10.0"

# The containment rule that makes the escape hatch cheap.
hits=$(cd "$W" && $GREP -rl "problem_details" r70web/src r70web/tests | sort | tr '\n' ' ' | sed 's/ $//')
assert "only problems.rs names the crate (containment rule)" "r70web/src/problems.rs" "$hits"

############################################################
printf -- '\n--- 5. the structural claim: #[non_exhaustive] across a crate boundary\n'
############################################################
# Single crate: the `_` arm is unreachable and the compiler says so.
S="$scratch/single/src"
mkdir -p "$S"
cat > "$scratch/single/Cargo.toml" <<'EOF'
[package]
name = "r70single"
version = "0.0.0"
edition = "2024"
publish = false
[dependencies]
EOF
cat > "$S/lib.rs" <<'EOF'
#[derive(Clone, Copy)]
#[non_exhaustive]
pub enum ErrorCode {
    A,
    B,
}
pub const fn code_of(code: ErrorCode) -> u16 {
    match code {
        ErrorCode::A => 404,
        ErrorCode::B => 409,
        _ => 500,
    }
}
EOF
if (cd "$scratch/single" && cargo build) > "$scratch/single.log" 2>&1; then
  contains "same-crate match: the _ arm draws 'unreachable pattern'" "$scratch/single.log" "unreachable pattern"
  contains "same-crate match: compiler says no value can reach it" "$scratch/single.log" "no value can reach this"
else
  bad "single-crate probe did not build"
  tail -20 "$scratch/single.log"
fi

# Cross crate: the identical arm is required and draws no warning.  The web
# crate already is that case, so assert against its own build log.
if $GREP -q "unreachable pattern" "$scratch/host-test.log"; then
  bad "cross-crate match: an unreachable-pattern warning appeared where none should"
else
  ok "cross-crate match: the same _ arm is reachable and draws no warning"
fi

############################################################
printf -- '\n--- 6. the crate source claims raw/opus.md makes\n'
############################################################
VEND="$HOME/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f"
PD="$VEND/problem_details-0.10.0"
AX="$VEND/axum-0.8.9"
if [ -d "$PD" ] && [ -d "$AX" ]; then
  contains "problem_details forbids unsafe" "$PD/src/lib.rs" "#![forbid(unsafe_code)]"
  contains "problem_details warns on missing docs" "$PD/src/lib.rs" "#![warn(missing_docs)]"
  contains "problem_details CONTENT_TYPE constant" "$PD/src/problem_details/json.rs" \
    'pub const CONTENT_TYPE: &'"'"'static str = "application/problem+json";'
  assert "problem_details.rs:117 is the utoipa ToSchema derive" \
    '#[cfg_attr(feature = "utoipa", derive(utoipa::ToSchema))]' \
    "$(sed -n '117p' "$PD/src/problem_details.rs")"
  assert "problem_details.rs:170 is schema(inline) on extensions" \
    '    #[cfg_attr(feature = "utoipa", schema(inline))]' \
    "$(sed -n '170p' "$PD/src/problem_details.rs")"
  assert "axum rejection.rs:11 — JsonDataError is 422" \
    '    #[status = UNPROCESSABLE_ENTITY]' "$(sed -n '11p' "$AX/src/extract/rejection.rs")"
  assert "axum rejection.rs:23 — JsonSyntaxError is 400" \
    '    #[status = BAD_REQUEST]' "$(sed -n '23p' "$AX/src/extract/rejection.rs")"
  assert "axum rejection.rs:34 — MissingJsonContentType is 415" \
    '    #[status = UNSUPPORTED_MEDIA_TYPE]' "$(sed -n '34p' "$AX/src/extract/rejection.rs")"
  assert "axum routing/mod.rs:345 — Router::fallback" \
    '    pub fn fallback<H, T>(self, handler: H) -> Self' "$(sed -n '345p' "$AX/src/routing/mod.rs")"
  assert "axum routing/mod.rs:374 — Router::method_not_allowed_fallback" \
    '    pub fn method_not_allowed_fallback<H, T>(self, handler: H) -> Self' \
    "$(sed -n '374p' "$AX/src/routing/mod.rs")"
  # No problem-details support anywhere in the framework tree.
  found=""
  for crate_dir in axum-0.8.9 axum-core-0.5.6 tower-0.5.3 hyper-1.11.1; do
    if [ -d "$VEND/$crate_dir/src" ]; then
      if $GREP -ril "problem+json" "$VEND/$crate_dir/src" >/dev/null 2>&1; then
        found="$found $crate_dir"
      fi
    else
      skip "$crate_dir not vendored on this host"
    fi
  done
  assert "no framework crate mentions problem+json (the envelope is not first-party)" "" "$found"
else
  skip "vendored crate sources (run cargo fetch first)"
fi

############################################################
printf '\n=== summary ===\n'
printf 'PASS %d  FAIL %d  SKIP %d  TOTAL %d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
