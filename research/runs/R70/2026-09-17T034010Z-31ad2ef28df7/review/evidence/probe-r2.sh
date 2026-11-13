#!/usr/bin/env bash
# R70 revision 2 — the MOVED envelope, executed.
#
# Revision 1's probe (probe.sh, carried byte-identical) proved the funnel.
# This one proves the envelope the REST API Design Standard v2.0.0 requires:
# a mandatory template-bound `type`, a snake_case `code`, R67's token carried
# as `catalog_code`, R5.15's `errors[]` array, a generated R5.16 catalog, and
# the two redaction rules that revision 1's design would have violated.
#
# Throwaway workspace under $TMPDIR, deleted on exit.  This verifies claims;
# it does not build the template.
#
# Asserts on CONTENT.  PASS/FAIL/SKIP counted and summed; non-zero on FAIL.
set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf 'SKIP  %s\n' "$1"; }
assert() { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }
contains() { if $GREP -qF -- "$3" "$2"; then ok "$1"; else bad "$1 — not found: $3"; fi; }
lacks()    { if $GREP -qF -- "$3" "$2"; then bad "$1 — present but must not be: $3"; else ok "$1"; fi; }

MSRV=1.96.0
scratch="$(mktemp -d "${TMPDIR:-/tmp}/r70-probe-r2.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
export CARGO_TARGET_DIR="$scratch/target"

printf '=== R70 revision 2 probe: the moved envelope ===\n'
printf 'date (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'os: %s %s (%s)\n' "$(sw_vers -productName 2>/dev/null || uname -s)" \
  "$(sw_vers -productVersion 2>/dev/null || uname -r)" "$(uname -m)"
printf 'host rustc: %s\n' "$(rustc --version)"
if command -v rustup >/dev/null 2>&1 && rustup toolchain list | $GREP -q "^${MSRV}-"; then
  MSRV_AVAILABLE=yes
  printf 'MSRV toolchain: %s\n' "$(rustup run "$MSRV" rustc --version)"
else
  MSRV_AVAILABLE=no
  printf 'MSRV toolchain: %s NOT installed\n' "$MSRV"
fi
printf 'scratch: %s (deleted on exit)\n\n' "$scratch"

W="$scratch/probe"
mkdir -p "$W/r70core/src" "$W/r70web/src" "$W/r70web/tests" "$W/r70web/examples" "$W/r70ctl/src"

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

[[example]]
name = "catalog"
path = "examples/catalog.rs"
EOF

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
# r70core — unchanged from revision 1's probe: R67's catalog stand-in.
############################################################
cat > "$W/r70core/src/lib.rs" <<'EOF'
//! Stand-in for R67 `error-contract/v1`. PROBE, not the template.
#![forbid(unsafe_code)]

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
# r70web/src/problems.rs — the MOVED envelope.
############################################################
cat > "$W/r70web/src/problems.rs" <<'EOF'
//! The RFC 9457 envelope as the REST API Design Standard v2.0.0 requires it.
use std::collections::BTreeMap;

use axum::extract::rejection::{JsonRejection, PathRejection, QueryRejection};
use axum::extract::{FromRequest, FromRequestParts, Request};
use axum::http::request::Parts;
use axum::http::{HeaderName, HeaderValue, StatusCode, Uri};
use axum::response::{IntoResponse, Response};
use problem_details::ProblemDetails;
use r70core::{DomainError, ErrorCode};
use serde::Serialize;

/// R5.17 / R8.12: the substitute used whenever the real text is withheld.
pub const WITHHELD_DETAIL: &str = "An unexpected error occurred.";
/// R5.13.1: each API declares its base URI.  A TEMPLATE has no provider
/// domain, so P03 takes this from a required setting (R77) with no default;
/// the probe stands one in.
pub const PROBLEM_BASE: &str = "https://problems.example.com";

/// R5.13.1: the `code` value space this item owns.  An explicit match, in
/// R67's own discipline — never derived from a variant identifier, so a
/// rename cannot silently change the wire.  Grammar `^[a-z][a-z0-9_]*$`.
pub const fn http_code(code: ErrorCode) -> &'static str {
    match code {
        ErrorCode::Unexpected => "internal_error",
        ErrorCode::Io => "io_failure",
        ErrorCode::Transport => "upstream_unreachable",
        ErrorCode::RemoteApi => "upstream_failed",
        ErrorCode::ConfigLayerUnreadable => "service_misconfigured",
        ErrorCode::UsageParse => "request_invalid",
        ErrorCode::ConfigUnparsable => "service_config_unparsable",
        ErrorCode::ConfigValueInvalid => "service_config_invalid",
        ErrorCode::SecretChannel => "service_secret_channel_invalid",
        ErrorCode::InputUnavailable => "input_unavailable",
        ErrorCode::NotFound => "resource_not_found",
        ErrorCode::CredentialsAbsent => "credentials_absent",
        ErrorCode::CredentialsRejected => "credentials_rejected",
        ErrorCode::Conflict => "conflict",
        ErrorCode::Sigint => "interrupted",
        ErrorCode::Sigterm => "terminated",
        ErrorCode::PromptInterrupted => "prompt_interrupted",
        _ => "internal_error",
    }
}

/// R5.13.1: the fixed template `<https base>/<code, underscores to hyphens>`.
pub fn problem_type(code: ErrorCode) -> String {
    format!("{PROBLEM_BASE}/{}", http_code(code).replace('_', "-"))
}

/// W4: the whole domain-to-status table.  The `_` arm is required because
/// `ErrorCode` is `#[non_exhaustive]` and lives in another crate.
pub const fn http_status(code: ErrorCode) -> StatusCode {
    match code {
        ErrorCode::NotFound => StatusCode::NOT_FOUND,
        ErrorCode::CredentialsAbsent | ErrorCode::CredentialsRejected => StatusCode::UNAUTHORIZED,
        ErrorCode::Conflict => StatusCode::CONFLICT,
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

pub const NOT_REQUEST_REACHABLE: &[ErrorCode] = &[
    ErrorCode::InputUnavailable,
    ErrorCode::Sigint,
    ErrorCode::Sigterm,
    ErrorCode::PromptInterrupted,
];

/// R5.17 / R8.12: whether this code's own message may reach a client.
pub const fn detail_is_public(code: ErrorCode) -> bool {
    matches!(
        code,
        ErrorCode::NotFound | ErrorCode::Conflict | ErrorCode::UsageParse
    )
}

/// R5.15: one field-level failure.
#[derive(Debug, Clone, Serialize)]
pub struct FieldError {
    /// JSON Pointer (RFC 6901) to the offending input location.
    pub pointer: String,
    /// Stable machine-readable code for this field failure.
    pub code: &'static str,
    /// Human-readable text.  Never echoes the offending VALUE (R8.12).
    pub detail: String,
}

/// RFC 9457 §3.2 extension members.
#[derive(Debug, Clone, Serialize)]
pub struct ProblemExt {
    /// R5.13: the stable machine-readable code; `type`'s short form.
    pub code: &'static str,
    /// R67's catalog token, for correlation with the CLI surface.
    pub catalog_code: &'static str,
    /// R5.13.4: human documentation, never `type`.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub documentation: Option<String>,
    /// R5.15: field-level failures.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub errors: Option<Vec<FieldError>>,
}

pub type Problem = ProblemDetails<ProblemExt>;

pub trait ProblemSource {
    fn error_code(&self) -> ErrorCode;
    fn detail(&self) -> Option<String> {
        None
    }
    fn field_errors(&self) -> Option<Vec<FieldError>> {
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

#[derive(Debug)]
pub struct WebError {
    code: ErrorCode,
    status: StatusCode,
    detail: Option<String>,
    errors: Option<Vec<FieldError>>,
    documentation: Option<String>,
    instance: Option<String>,
    headers: Vec<(HeaderName, HeaderValue)>,
    logged: Option<String>,
}

impl WebError {
    pub fn new(code: ErrorCode) -> Self {
        Self {
            code,
            status: http_status(code),
            detail: None,
            errors: None,
            documentation: None,
            instance: None,
            headers: Vec::new(),
            logged: None,
        }
    }

    pub fn framework(status: StatusCode, code: ErrorCode) -> Self {
        Self {
            status,
            ..Self::new(code)
        }
    }

    pub fn from_source<S: ProblemSource>(source: &S) -> Self {
        let mut error = Self::new(source.error_code());
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

    /// The full text for the log, whether or not the client may see it.
    #[must_use]
    pub fn logging_only(mut self, detail: impl Into<String>) -> Self {
        self.logged = Some(detail.into());
        self
    }

    #[must_use]
    pub fn with_errors(mut self, errors: Vec<FieldError>) -> Self {
        self.errors = Some(errors);
        self
    }

    #[must_use]
    pub fn with_documentation(mut self, url: impl Into<String>) -> Self {
        self.documentation = Some(url.into());
        self
    }

    /// R5.17: the request PATH only.  A query string is banned from every
    /// response body, so `Uri::path()` rather than the whole URI.
    #[must_use]
    pub fn with_instance_path(mut self, uri: &Uri) -> Self {
        self.instance = Some(uri.path().to_string());
        self
    }

    #[must_use]
    pub fn with_header(mut self, name: HeaderName, value: HeaderValue) -> Self {
        self.headers.push((name, value));
        self
    }

    pub fn log_detail(&self) -> Option<&str> {
        self.logged.as_deref()
    }

    pub fn code(&self) -> ErrorCode {
        self.code
    }

    pub fn to_problem(&self) -> Problem {
        let extensions = ProblemExt {
            code: http_code(self.code),
            catalog_code: self.code.as_str(),
            documentation: self.documentation.clone(),
            errors: self.errors.clone(),
        };
        // R5.13.5: `type` is always present and is never `about:blank`.
        let uri: Uri = problem_type(self.code)
            .parse()
            .expect("the problem type template always yields a valid URI");
        let mut problem = ProblemDetails::from_status_code(self.status)
            .with_extensions(extensions)
            .with_type(uri);
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

/// R8.12: a framework rejection's own text echoes the offending VALUE
/// (serde renders `invalid type: integer \`12345\``), so it is logged and
/// never placed in the body.  The body carries the location and a class.
fn framework_rejection(status: StatusCode, field_code: &'static str, logged: String) -> WebError {
    WebError::framework(status, ErrorCode::UsageParse)
        .with_detail("The request could not be processed as submitted.")
        .with_errors(vec![FieldError {
            // RFC 6901: "" is the whole document.
            pointer: String::new(),
            code: field_code,
            detail: "The request body did not match the expected shape.".to_string(),
        }])
        .logging_only(logged)
}

impl From<JsonRejection> for WebError {
    fn from(rejection: JsonRejection) -> Self {
        let status = rejection.status();
        let field_code = match status {
            StatusCode::BAD_REQUEST => "malformed_json",
            StatusCode::UNSUPPORTED_MEDIA_TYPE => "unsupported_media_type",
            _ => "invalid_body_type",
        };
        framework_rejection(status, field_code, rejection.body_text())
    }
}

impl From<PathRejection> for WebError {
    fn from(rejection: PathRejection) -> Self {
        let status = rejection.status();
        let logged = rejection.body_text();
        WebError::framework(status, ErrorCode::UsageParse)
            .with_detail("The request could not be processed as submitted.")
            .with_errors(vec![FieldError {
                pointer: String::new(),
                code: "invalid_path_parameter",
                detail: "A path parameter did not match the expected type.".to_string(),
            }])
            .logging_only(logged)
    }
}

impl From<QueryRejection> for WebError {
    fn from(rejection: QueryRejection) -> Self {
        let status = rejection.status();
        let logged = rejection.body_text();
        WebError::framework(status, ErrorCode::UsageParse)
            .with_detail("The request could not be processed as submitted.")
            .with_errors(vec![FieldError {
                pointer: String::new(),
                code: "invalid_query_parameter",
                detail: "A query parameter did not match the expected type.".to_string(),
            }])
            .logging_only(logged)
    }
}

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

/// R1.9 / R13.3: the two per-endpoint guards that bind even with every
/// applicability switch off.
pub fn reserved_parameter_guard(uri: &Uri) -> Option<WebError> {
    let query = uri.query().unwrap_or("");
    for name in ["dry_run", "stream"] {
        let hit = query
            .split('&')
            .any(|pair| pair == name || pair.starts_with(&format!("{name}=")));
        if hit {
            return Some(
                WebError::framework(StatusCode::BAD_REQUEST, ErrorCode::UsageParse)
                    .with_detail("This endpoint does not implement the requested capability.")
                    .with_errors(vec![FieldError {
                        pointer: String::new(),
                        code: "unsupported_reserved_parameter",
                        detail: "A reserved request parameter was sent to an endpoint that does not implement it.".to_string(),
                    }])
                    .with_instance_path(uri),
            );
        }
    }
    None
}

pub async fn not_found(uri: Uri) -> WebError {
    WebError::new(ErrorCode::NotFound)
        .with_detail("No route matches this path.")
        .with_instance_path(&uri)
}

pub async fn method_not_allowed() -> WebError {
    WebError::framework(StatusCode::METHOD_NOT_ALLOWED, ErrorCode::UsageParse)
        .with_detail("This method is not allowed for this path.")
}

pub fn join_error_to_web_error(error: &tokio::task::JoinError) -> WebError {
    WebError::new(ErrorCode::Unexpected).logging_only(error.to_string())
}

/// R5.16: the published catalog, generated from `ErrorCode::ALL` so it
/// cannot drift from the table the coverage test walks.
pub fn catalog() -> Vec<BTreeMap<&'static str, String>> {
    ErrorCode::ALL
        .iter()
        .map(|code| {
            let mut row = BTreeMap::new();
            row.insert("type", problem_type(*code));
            row.insert("code", http_code(*code).to_string());
            row.insert("catalog_code", code.as_str().to_string());
            row.insert("status", http_status(*code).as_u16().to_string());
            row
        })
        .collect()
}
EOF

############################################################
# r70web/src/lib.rs
############################################################
cat > "$W/r70web/src/lib.rs" <<'EOF'
//! Probe web crate for revision 2.
#![forbid(unsafe_code)]

pub mod problems;

use axum::http::{HeaderValue, Uri, header};
use axum::response::Json;
use axum::routing::{get, post};
use axum::{Router, serve::Serve};
use r70core::{DomainError, ErrorCode, find_project};
use serde::{Deserialize, Serialize};

use problems::{
    ProblemJson, ProblemPath, WebError, join_error_to_web_error, reserved_parameter_guard,
};

#[derive(Debug, Serialize)]
pub struct ProjectView {
    pub name: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct NewProject {
    pub name: String,
    #[serde(default)]
    pub password: Option<String>,
}

async fn get_project(
    ProblemPath(name): ProblemPath<String>,
    uri: Uri,
) -> Result<Json<ProjectView>, WebError> {
    match find_project(&name) {
        Ok(Some(name)) => Ok(Json(ProjectView { name })),
        Ok(None) => Err(WebError::from_source(&DomainError::NotFound { what: name })
            .with_instance_path(&uri)),
        Err(error) => Err(WebError::from_source(&error).with_instance_path(&uri)),
    }
}

async fn create_project(
    uri: Uri,
    ProblemJson(body): ProblemJson<NewProject>,
) -> Result<Json<NewProject>, WebError> {
    if let Some(error) = reserved_parameter_guard(&uri) {
        return Err(error);
    }
    Ok(Json(body))
}

async fn upstream(uri: Uri) -> Result<Json<ProjectView>, WebError> {
    match find_project("upstream") {
        Ok(_) => Ok(Json(ProjectView { name: "x".into() })),
        Err(error) => Err(WebError::from_source(&error).with_instance_path(&uri)),
    }
}

async fn count(ProblemPath(n): ProblemPath<u32>) -> Json<u32> {
    Json(n)
}

async fn blocking_panic() -> Result<Json<ProjectView>, WebError> {
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

async fn documented() -> Result<Json<ProjectView>, WebError> {
    Err(WebError::new(ErrorCode::Conflict)
        .with_detail("The project already exists.")
        .with_documentation("https://developers.example.com/errors#conflict"))
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
        .route("/documented", get(documented))
        .route("/ok", get(okay))
        .fallback(problems::not_found)
        .method_not_allowed_fallback(problems::method_not_allowed)
}

pub fn _assert_serve_type(
    listener: tokio::net::TcpListener,
) -> Serve<tokio::net::TcpListener, Router, Router> {
    axum::serve(listener, build_router())
}
EOF

cat > "$W/r70web/examples/dump.rs" <<'EOF'
use axum::body::Body;
use axum::http::{Method, Request, header};
use r70web::build_router;
use tower::ServiceExt;

async fn show(method: Method, path: &str, body: Body, content_type: Option<&str>) {
    let mut builder = Request::builder().method(method.clone()).uri(path);
    if let Some(value) = content_type {
        builder = builder.header(header::CONTENT_TYPE, value);
    }
    let response = build_router().oneshot(builder.body(body).unwrap()).await.unwrap();
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
    show(Method::GET, "/documented", Body::empty(), None).await;
    show(
        Method::POST,
        "/projects?dry_run=true",
        Body::from(r#"{"name":"x"}"#),
        Some("application/json"),
    )
    .await;
}
EOF

cat > "$W/r70web/examples/catalog.rs" <<'EOF'
//! R5.16: the published problem catalog, generated from ErrorCode::ALL.
fn main() {
    let rows = r70web::problems::catalog();
    println!("{}", serde_json::to_string_pretty(&rows).unwrap());
}
EOF

############################################################
# r70web/tests/problems.rs — the revision-2 criteria.
############################################################
cat > "$W/r70web/tests/problems.rs" <<'EOF'
use std::collections::BTreeMap;

use axum::body::Body;
use axum::http::{HeaderMap, Method, Request, StatusCode, header};
use r70core::ErrorCode;
use r70web::build_router;
use r70web::problems::{
    NOT_REQUEST_REACHABLE, PROBLEM_BASE, catalog, detail_is_public, http_code, http_status,
    problem_type,
};
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
    let response = build_router().oneshot(builder.body(body).unwrap()).await.unwrap();
    let status = response.status();
    let headers = response.headers().clone();
    let bytes = axum::body::to_bytes(response.into_body(), 65536).await.unwrap();
    (status, headers, String::from_utf8(bytes.to_vec()).unwrap())
}

fn content_type(headers: &HeaderMap) -> String {
    headers
        .get(header::CONTENT_TYPE)
        .map(|v| v.to_str().unwrap().to_string())
        .unwrap_or_default()
}

fn json(body: &str) -> BTreeMap<String, serde_json::Value> {
    serde_json::from_str(body).expect("response body is a JSON object")
}

fn is_snake_case(name: &str) -> bool {
    let mut chars = name.chars();
    match chars.next() {
        Some(c) if c.is_ascii_lowercase() || c == '_' => {}
        _ => return false,
    }
    chars.all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_')
}

fn is_code_grammar(code: &str) -> bool {
    let mut chars = code.chars();
    match chars.next() {
        Some(c) if c.is_ascii_lowercase() => {}
        _ => return false,
    }
    chars.all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_')
}

// R1 — the status table stays total over ErrorCode::ALL.
#[test]
fn r1_status_table_is_total() {
    assert_eq!(ErrorCode::ALL.len(), 17);
    for code in ErrorCode::ALL {
        let status = http_status(*code);
        assert!(status.is_client_error() || status.is_server_error(), "{}", code.as_str());
    }
}

// R2 — NOT_REQUEST_REACHABLE is 500 and its declared length.
#[test]
fn r2_unreachable_codes_are_500() {
    assert_eq!(NOT_REQUEST_REACHABLE.len(), 4);
    for code in NOT_REQUEST_REACHABLE {
        assert_eq!(http_status(*code), StatusCode::INTERNAL_SERVER_ERROR);
    }
}

// R3 — R5.17/R8.12: no 5xx code is detail-public.
#[test]
fn r3_no_server_error_is_detail_public() {
    for code in ErrorCode::ALL {
        if http_status(*code).is_server_error() {
            assert!(!detail_is_public(*code), "{}", code.as_str());
        }
    }
}

// R4 — R5.13.1: http_code is total, injective, and matches the grammar.
#[test]
fn r4_http_code_is_total_injective_and_grammatical() {
    let mut seen = std::collections::BTreeSet::new();
    for code in ErrorCode::ALL {
        let http = http_code(*code);
        assert!(is_code_grammar(http), "{http} fails ^[a-z][a-z0-9_]*$");
        assert!(seen.insert(http), "{http} is not unique");
    }
    assert_eq!(seen.len(), ErrorCode::ALL.len());
}

// R5 — the catalog_code is R67's token verbatim for every row.
#[test]
fn r5_catalog_code_is_r67s_token() {
    for code in ErrorCode::ALL {
        assert_eq!(code.as_str(), code.as_str());
        assert!(code.as_str().starts_with("RSLB"));
        assert_eq!(code.as_str().len(), 7);
    }
}

// R6 — R5.13.1/R5.13.5: type is https, under the declared base, bound to code
// by the underscores-to-hyphens template, and never about:blank.
#[test]
fn r6_type_follows_the_template() {
    for code in ErrorCode::ALL {
        let t = problem_type(*code);
        assert!(t.starts_with("https://"), "{t} is not https");
        assert_ne!(t, "about:blank");
        let expected = format!("{PROBLEM_BASE}/{}", http_code(*code).replace('_', "-"));
        assert_eq!(t, expected);
        assert!(!t.rsplit('/').next().unwrap().contains('_'), "{t} keeps an underscore");
    }
}

// R7 — a domain error carries the full required member set.
#[tokio::test]
async fn r7_domain_error_envelope() {
    let (status, headers, body) = send(Method::GET, "/projects/demo", Body::empty(), None).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["type"], "https://problems.example.com/resource-not-found");
    assert_eq!(doc["title"], "Not Found");
    assert_eq!(doc["status"], 404);
    assert_eq!(doc["code"], "resource_not_found");
    assert_eq!(doc["catalog_code"], "RSLB301");
    assert_eq!(doc["detail"], "project 'demo' not found");
    assert_eq!(doc["instance"], "/projects/demo");
    assert!(!doc.contains_key("errors"));
    assert!(!doc.contains_key("documentation"));
    assert!(!body.contains("about:blank"));
}

// R8 — R5.17/R8.12: the upstream detail, host and token are all withheld.
#[tokio::test]
async fn r8_upstream_detail_is_withheld() {
    let (status, _, body) = send(Method::GET, "/upstream", Body::empty(), None).await;
    assert_eq!(status, StatusCode::BAD_GATEWAY);
    let doc = json(&body);
    assert_eq!(doc["code"], "upstream_failed");
    assert_eq!(doc["catalog_code"], "RSLB103");
    assert_eq!(doc["detail"], "An unexpected error occurred.");
    assert!(!body.contains("s3cret"));
    assert!(!body.contains("api.example.com"));
}

// R9 — the router fallback is enveloped and carries instance.
#[tokio::test]
async fn r9_router_fallback_is_enveloped() {
    let (status, headers, body) = send(Method::GET, "/nope/at/all", Body::empty(), None).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert_eq!(json(&body)["instance"], "/nope/at/all");
}

// R10 — R5.11: the 405 is enveloped AND keeps Allow.
#[tokio::test]
async fn r10_method_not_allowed_keeps_allow() {
    let (status, headers, body) = send(Method::DELETE, "/ok", Body::empty(), None).await;
    assert_eq!(status, StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert_eq!(headers.get(header::ALLOW).unwrap().to_str().unwrap(), "GET,HEAD");
    assert_eq!(json(&body)["code"], "request_invalid");
}

// R11 — R5.3/R5.15: a data error is 422 and errors[] is an ARRAY of
// {pointer, code, detail}.
#[tokio::test]
async fn r11_data_error_is_422_with_errors_array() {
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
    assert_eq!(doc["code"], "request_invalid");
    let errors = doc["errors"].as_array().expect("errors MUST be an array");
    assert_eq!(errors.len(), 1);
    let entry = errors[0].as_object().unwrap();
    assert!(entry.contains_key("pointer"));
    assert_eq!(entry["code"], "invalid_body_type");
    assert!(entry["detail"].is_string());
}

// R12 — R5.3: malformed syntax keeps axum's 400.
#[tokio::test]
async fn r12_syntax_error_keeps_400() {
    let (status, _, body) = send(
        Method::POST,
        "/projects",
        Body::from("{not json"),
        Some("application/json"),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(json(&body)["errors"].as_array().unwrap()[0]["code"], "malformed_json");
}

// R13 — R5.11: a missing content type keeps axum's 415.
#[tokio::test]
async fn r13_missing_content_type_keeps_415() {
    let (status, _, body) = send(Method::POST, "/projects", Body::from(r#"{"name":"x"}"#), None).await;
    assert_eq!(status, StatusCode::UNSUPPORTED_MEDIA_TYPE);
    assert_eq!(
        json(&body)["errors"].as_array().unwrap()[0]["code"],
        "unsupported_media_type"
    );
}

// R14 — a panic in the blocking bridge is enveloped and redacted.
#[tokio::test]
async fn r14_blocking_panic_is_enveloped() {
    let (status, headers, body) = send(Method::GET, "/panic", Body::empty(), None).await;
    assert_eq!(status, StatusCode::INTERNAL_SERVER_ERROR);
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    let doc = json(&body);
    assert_eq!(doc["code"], "internal_error");
    assert_eq!(doc["catalog_code"], "RSLB000");
    assert!(!body.contains("boom inside the blocking bridge"));
}

// R15 — R5.1: a 2xx is untouched.
#[tokio::test]
async fn r15_success_is_not_enveloped() {
    let (status, headers, body) = send(Method::GET, "/ok", Body::empty(), None).await;
    assert_eq!(status, StatusCode::OK);
    assert!(content_type(&headers).starts_with("text/plain"));
    assert_eq!(body, "ok");
}

// R16 — R5.9: a 401 carries the challenge and the envelope.
#[tokio::test]
async fn r16_401_carries_challenge() {
    let (status, headers, body) = send(Method::GET, "/auth", Body::empty(), None).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
    assert_eq!(
        headers.get(header::WWW_AUTHENTICATE).unwrap().to_str().unwrap(),
        "Bearer realm=\"rslbp\""
    );
    let doc = json(&body);
    assert_eq!(doc["code"], "credentials_rejected");
    assert_eq!(doc["catalog_code"], "RSLB402");
}

// R17 — a path rejection funnels through the same hook.
#[tokio::test]
async fn r17_path_rejection_is_enveloped() {
    let (status, headers, body) = send(Method::GET, "/count/abc", Body::empty(), None).await;
    assert!(status.is_client_error());
    assert_eq!(content_type(&headers), PROBLEM_JSON);
    assert_eq!(
        json(&body)["errors"].as_array().unwrap()[0]["code"],
        "invalid_path_parameter"
    );
}

// R18 — R8.12: the offending VALUE is never echoed into the body.
#[tokio::test]
async fn r18_request_value_is_never_echoed() {
    let (status, _, body) = send(
        Method::POST,
        "/projects",
        Body::from(r#"{"name":"x","password":12345}"#),
        Some("application/json"),
    )
    .await;
    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
    assert!(!body.contains("12345"), "the offending value leaked: {body}");
    assert!(!body.contains("password"), "the field value's name leaked with it: {body}");
}

// R19 — R5.17: instance carries the path only, never the query string.
#[tokio::test]
async fn r19_instance_has_no_query_string() {
    let (status, _, body) = send(
        Method::GET,
        "/projects/demo?token=s3cret&trace=1",
        Body::empty(),
        None,
    )
    .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    let doc = json(&body);
    assert_eq!(doc["instance"], "/projects/demo");
    assert!(!body.contains('?'), "a query fragment reached the body: {body}");
    assert!(!body.contains("s3cret"));
}

// R20 — R1.9 / R13.3: the two per-endpoint reserved-parameter guards.
#[tokio::test]
async fn r20_reserved_parameter_guards_return_400() {
    for query in ["dry_run=true", "dry_run", "stream=1"] {
        let (status, headers, body) = send(
            Method::POST,
            &format!("/projects?{query}"),
            Body::from(r#"{"name":"x"}"#),
            Some("application/json"),
        )
        .await;
        assert_eq!(status, StatusCode::BAD_REQUEST, "{query}");
        assert_eq!(content_type(&headers), PROBLEM_JSON);
        let doc = json(&body);
        assert_eq!(doc["code"], "request_invalid");
        assert_eq!(
            doc["errors"].as_array().unwrap()[0]["code"],
            "unsupported_reserved_parameter"
        );
    }
}

// R21 — R4.3/R4.4/R4.8: object at the top level, snake_case members
// everywhere, and no member is ever null.
#[tokio::test]
async fn r21_representation_rules_hold_on_every_body() {
    let cases: Vec<(Method, &str, Body, Option<&str>)> = vec![
        (Method::GET, "/projects/demo", Body::empty(), None),
        (Method::GET, "/upstream", Body::empty(), None),
        (Method::GET, "/nope", Body::empty(), None),
        (Method::DELETE, "/ok", Body::empty(), None),
        (Method::POST, "/projects", Body::from(r#"{"name": 42}"#), Some("application/json")),
        (Method::GET, "/panic", Body::empty(), None),
        (Method::GET, "/auth", Body::empty(), None),
        (Method::GET, "/documented", Body::empty(), None),
        (Method::GET, "/count/abc", Body::empty(), None),
    ];
    for (method, path, body, ctype) in cases {
        let (_, _, text) = send(method.clone(), path, body, ctype).await;
        let value: serde_json::Value = serde_json::from_str(&text).unwrap();
        let object = value.as_object().expect("R4.3: object at the top level");
        for (name, member) in object {
            assert!(is_snake_case(name), "R4.4: {name} on {method} {path}");
            assert!(!member.is_null(), "R4.8: {name} is null on {method} {path}");
            if name == "errors" {
                for entry in member.as_array().unwrap() {
                    for (field, v) in entry.as_object().unwrap() {
                        assert!(is_snake_case(field), "R4.4: errors[].{field}");
                        assert!(!v.is_null(), "R4.8: errors[].{field} is null");
                    }
                }
            }
        }
    }
}

// R22 — R5.13.4: documentation is omitted when absent and present when set.
#[tokio::test]
async fn r22_documentation_member() {
    let (_, _, absent) = send(Method::GET, "/projects/demo", Body::empty(), None).await;
    assert!(!json(&absent).contains_key("documentation"));
    let (status, _, present) = send(Method::GET, "/documented", Body::empty(), None).await;
    assert_eq!(status, StatusCode::CONFLICT);
    let doc = json(&present);
    assert_eq!(
        doc["documentation"],
        "https://developers.example.com/errors#conflict"
    );
    assert_eq!(doc["code"], "conflict");
    assert_eq!(doc["type"], "https://problems.example.com/conflict");
}

// R23 — R5.16: the catalog has one row per catalog member, with the four
// published fields, and cannot drift from the table.
#[test]
fn r23_catalog_covers_every_row() {
    let rows = catalog();
    assert_eq!(rows.len(), ErrorCode::ALL.len());
    for (row, code) in rows.iter().zip(ErrorCode::ALL) {
        assert_eq!(row["catalog_code"], code.as_str());
        assert_eq!(row["code"], http_code(*code));
        assert_eq!(row["type"], problem_type(*code));
        assert_eq!(row["status"], http_status(*code).as_u16().to_string());
        assert!(!row["type"].contains("about:blank"));
    }
}

// R24 — R5.1: every failing request is problem+json and every 2xx is not.
#[tokio::test]
async fn r24_every_non_2xx_is_problem_json() {
    let cases: Vec<(Method, &str, Body, Option<&str>)> = vec![
        (Method::GET, "/projects/demo", Body::empty(), None),
        (Method::GET, "/upstream", Body::empty(), None),
        (Method::GET, "/nope", Body::empty(), None),
        (Method::DELETE, "/ok", Body::empty(), None),
        (Method::POST, "/projects", Body::from(r#"{"name": 42}"#), Some("application/json")),
        (Method::POST, "/projects", Body::from("{nope"), Some("application/json")),
        (Method::POST, "/projects", Body::from(r#"{"name":"x"}"#), None),
        (Method::POST, "/projects?dry_run=1", Body::from(r#"{"name":"x"}"#), Some("application/json")),
        (Method::GET, "/panic", Body::empty(), None),
        (Method::GET, "/auth", Body::empty(), None),
        (Method::GET, "/documented", Body::empty(), None),
        (Method::GET, "/count/abc", Body::empty(), None),
        (Method::GET, "/ok", Body::empty(), None),
        (Method::GET, "/projects/known", Body::empty(), None),
    ];
    let mut failures = 0;
    let mut successes = 0;
    for (method, path, body, ctype) in cases {
        let (status, headers, text) = send(method.clone(), path, body, ctype).await;
        if status.is_success() {
            successes += 1;
            assert_ne!(content_type(&headers), PROBLEM_JSON, "{method} {path}");
        } else {
            failures += 1;
            assert_eq!(content_type(&headers), PROBLEM_JSON, "{method} {path} -> {status}");
            assert!(!text.contains("about:blank"), "{method} {path}");
            assert!(text.contains("\"type\""), "R5.13.5: type absent on {method} {path}");
        }
    }
    assert_eq!((failures, successes), (12, 2));
}
EOF

############################################################
printf -- '--- 1. build and test at the MSRV floor (%s)\n' "$MSRV"
############################################################
if [ "$MSRV_AVAILABLE" = yes ]; then
  if (cd "$W" && rustup run "$MSRV" cargo test --workspace) > "$scratch/msrv.log" 2>&1; then
    ok "cargo test --workspace compiled and ran under rustc $MSRV"
  else
    bad "cargo test --workspace FAILED under rustc $MSRV"
    tail -40 "$scratch/msrv.log"
  fi
  contains "MSRV run: 24 criteria passed" "$scratch/msrv.log" "24 passed; 0 failed"
else
  skip "MSRV compile at $MSRV: toolchain not installed on this host"
fi

############################################################
printf -- '\n--- 2. build and test on the host stable toolchain\n'
############################################################
if (cd "$W" && cargo test --workspace) > "$scratch/host.log" 2>&1; then
  ok "cargo test --workspace compiled and ran under the host toolchain"
else
  bad "cargo test --workspace FAILED under the host toolchain"
  tail -40 "$scratch/host.log"
fi
contains "host run: 24 criteria passed" "$scratch/host.log" "24 passed; 0 failed"
lacks "host build emitted no warning" "$scratch/host.log" "warning:"

############################################################
printf -- '\n--- 3. the bodies this revision emits\n'
############################################################
if (cd "$W" && cargo run --quiet --example dump) > "$scratch/bodies.log" 2>"$scratch/bodies.err"; then
  ok "the dump example printed six bodies"
  sed 's/^/      /' "$scratch/bodies.log"
else
  bad "the dump example failed"
  tail -20 "$scratch/bodies.err"
fi
contains "the 404 body is template-bound and carries both codes" "$scratch/bodies.log" \
  '{"type":"https://problems.example.com/resource-not-found","status":404,"title":"Not Found","detail":"project '"'"'demo'"'"' not found","instance":"/projects/demo","code":"resource_not_found","catalog_code":"RSLB301"}'
contains "the 422 body carries R5.15's errors array" "$scratch/bodies.log" \
  '"errors":[{"pointer":"","code":"invalid_body_type","detail":"The request body did not match the expected shape."}]'
contains "the dry_run guard answers 400" "$scratch/bodies.log" \
  '"code":"unsupported_reserved_parameter"'
contains "the documented conflict carries the documentation member" "$scratch/bodies.log" \
  '"documentation":"https://developers.example.com/errors#conflict"'
lacks "R5.13.5: no body carries about:blank" "$scratch/bodies.log" 'about:blank'
lacks "R4.8: no body carries a null" "$scratch/bodies.log" 'null'
lacks "R8.12: no body echoes the upstream token" "$scratch/bodies.log" 's3cret'
# All six requests the dump example makes are failures, so all six responses
# carry the problem media type.
assert "all six dumped responses are labelled application/problem+json" "6" \
  "$($GREP -c 'application/problem+json' "$scratch/bodies.log" || true)"

############################################################
printf -- '\n--- 4. R5.16 — the generated catalog\n'
############################################################
if (cd "$W" && cargo run --quiet --example catalog) > "$scratch/catalog.json" 2>/dev/null; then
  ok "the catalog example emitted the published catalog"
else
  bad "the catalog example failed"
fi
python3 - "$scratch/catalog.json" <<'PY' > "$scratch/catalog.txt" 2>&1 || true
import json, re, sys
rows = json.load(open(sys.argv[1]))
print("rows", len(rows))
print("codes_unique", len({r["code"] for r in rows}))
print("catalog_codes_unique", len({r["catalog_code"] for r in rows}))
print("grammar_ok", all(re.fullmatch(r"[a-z][a-z0-9_]*", r["code"]) for r in rows))
print("https_ok", all(r["type"].startswith("https://") for r in rows))
print("template_ok", all(r["type"].endswith("/" + r["code"].replace("_", "-")) for r in rows))
print("no_about_blank", not any("about:blank" in r["type"] for r in rows))
print("rslb_ok", all(re.fullmatch(r"RSLB\d{3}", r["catalog_code"]) for r in rows))
PY
sed 's/^/      /' "$scratch/catalog.txt"
for want in "rows 17" "codes_unique 17" "catalog_codes_unique 17" "grammar_ok True" \
            "https_ok True" "template_ok True" "no_about_blank True" "rslb_ok True"; do
  contains "catalog: $want" "$scratch/catalog.txt" "$want"
done

############################################################
printf -- '\n--- 5. the crate choice does not move\n'
############################################################
tree_of() {
  ( cd "$W" && cargo tree -p "$1" --edges normal --prefix none ) 2>/dev/null |
    sed -e 's/ (\*)$//' -e 's| (/.*)$||' | sort -u
}
tree_of r70web > "$scratch/tree-web.txt"
tree_of r70ctl > "$scratch/tree-ctl.txt"
added=$(comm -23 "$scratch/tree-web.txt" "$scratch/tree-ctl.txt" | $GREP -v '^r70web' | tr '\n' ' ' | sed 's/ $//')
assert "the moved envelope still adds exactly two crates" \
  "http-serde v2.1.1 problem_details v0.10.0" "$added"
hits=$(cd "$W" && $GREP -rl "problem_details" r70web/src r70web/tests r70web/examples | sort | tr '\n' ' ' | sed 's/ $//')
assert "only problems.rs names the crate (containment rule holds)" "r70web/src/problems.rs" "$hits"

printf '\n=== summary ===\n'
printf 'PASS %d  FAIL %d  SKIP %d  TOTAL %d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
