//! Synchronous HTTP adapter for [`ProjectsPort`] backed by `ureq` (`R01`, `R03`, `R05`, `R48`,
//! `OV-18`).
//!
//! Gated behind the root library's default-on `http` feature so `crates/core` stays completely
//! free of HTTP client crates and TLS stacks, and minimal library consumers can opt out with
//! `default-features = false`. Every HTTP status and schema-drift condition is mapped explicitly
//! per operation.

use std::fmt;
use std::sync::Arc;
use std::time::Duration;

use rs_launch_blueprint_core::{
    CreateProjectInput, PortError, Project, ProjectQuery, ProjectsPort, Token,
};
use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

/// Default global request timeout applied by [`HttpProjectsPort::new`].
pub const DEFAULT_HTTP_TIMEOUT: Duration = Duration::from_secs(30);

/// Optional callback invoked on every outbound HTTP request to supply additional headers (for
/// example, W3C Trace Context `traceparent` / `tracestate` headers when used from an
/// OpenTelemetry-instrumented web service) without coupling the standalone library to
/// `opentelemetry` crates (`OV-18`, `R78`).
pub type HeaderInjector = Arc<dyn Fn() -> Vec<(String, String)> + Send + Sync>;

/// Concrete HTTP [`ProjectsPort`] adapter using blocking `ureq` (`R05`).
///
/// The internal module cannot be deep-imported by external consumers (`R04`):
///
/// ```compile_fail,E0603
/// use rs_launch_blueprint::http_adapter::HttpProjectsPort;
/// ```
pub struct HttpProjectsPort {
    base_url: String,
    token: Token,
    agent: ureq::Agent,
    header_injector: Option<HeaderInjector>,
}

impl fmt::Debug for HttpProjectsPort {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("HttpProjectsPort")
            .field("base_url", &self.base_url)
            .field("token", &self.token)
            .field("has_header_injector", &self.header_injector.is_some())
            .finish_non_exhaustive()
    }
}

impl HttpProjectsPort {
    /// Construct an [`HttpProjectsPort`] targeting `base_url` with [`DEFAULT_HTTP_TIMEOUT`].
    #[must_use]
    pub fn new(base_url: impl Into<String>, token: Token) -> Self {
        Self::with_timeout(base_url, token, DEFAULT_HTTP_TIMEOUT)
    }

    /// Construct an [`HttpProjectsPort`] with an explicit global request timeout.
    #[must_use]
    pub fn with_timeout(base_url: impl Into<String>, token: Token, timeout: Duration) -> Self {
        let base_url = base_url.into().trim_end_matches('/').to_owned();
        let config = ureq::Agent::config_builder()
            .http_status_as_error(false)
            .timeout_global(Some(timeout))
            .build();
        let agent = config.new_agent();
        Self {
            base_url,
            token,
            agent,
            header_injector: None,
        }
    }

    /// Attach an optional [`HeaderInjector`] called on every outbound HTTP request.
    #[must_use]
    pub fn with_header_injector(mut self, injector: HeaderInjector) -> Self {
        self.header_injector = Some(injector);
        self
    }

    /// Return the normalized base URL (without trailing slash).
    #[must_use]
    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    fn bearer_header(&self) -> String {
        format!("Bearer {}", self.token.expose_secret())
    }

    fn outbound_headers(&self) -> Vec<(String, String)> {
        self.header_injector
            .as_ref()
            .map_or_else(Vec::new, |inject| inject())
    }
}

#[derive(Debug, Deserialize)]
struct Envelope<T> {
    data: T,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum WireId {
    Str(String),
    Uint(u64),
    Int(i64),
}

impl WireId {
    fn into_string(self) -> String {
        match self {
            Self::Str(s) => s,
            Self::Uint(n) => n.to_string(),
            Self::Int(n) => n.to_string(),
        }
    }
}

#[derive(Debug, Deserialize)]
struct WireWorkspaceObject {
    name: String,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum WireWorkspace {
    Object(WireWorkspaceObject),
    Name(String),
}

impl WireWorkspace {
    fn into_name(self) -> String {
        match self {
            Self::Object(obj) => obj.name,
            Self::Name(name) => name,
        }
    }
}

#[derive(Debug, Deserialize)]
struct WireProject {
    gid: Option<WireId>,
    id: Option<WireId>,
    name: String,
    workspace: Option<WireWorkspace>,
}

impl WireProject {
    fn into_domain(self) -> Result<Project, PortError> {
        let id = self
            .gid
            .or(self.id)
            .map(WireId::into_string)
            .filter(|s| !s.is_empty())
            .ok_or_else(|| PortError::RemoteApi {
                detail: "remote project payload missing 'gid'/'id' field".to_owned(),
                source: None,
            })?;
        Ok(Project {
            id,
            name: self.name,
            workspace: self.workspace.map(WireWorkspace::into_name),
        })
    }
}

#[derive(Debug, Serialize)]
struct CreateProjectPayload<'a> {
    name: &'a str,
    #[serde(skip_serializing_if = "Option::is_none")]
    workspace: Option<&'a str>,
}

fn map_error_status(operation: &str, status: u16) -> PortError {
    match status {
        401 | 403 => PortError::Unauthorized {
            detail: format!("{operation} rejected with HTTP {status}"),
            source: None,
        },
        409 => PortError::Conflict {
            detail: format!("{operation} reported conflict (HTTP 409)"),
            source: None,
        },
        _ => PortError::RemoteApi {
            detail: format!("{operation} returned unexpected HTTP {status}"),
            source: None,
        },
    }
}

fn read_json_body<T: serde::de::DeserializeOwned>(
    operation: &str,
    mut response: ureq::http::Response<ureq::Body>,
) -> Result<T, PortError> {
    let raw = response
        .body_mut()
        .read_to_string()
        .map_err(|err| PortError::Transport {
            source: Box::new(err),
        })?;
    serde_json::from_str::<T>(&raw).map_err(|err| PortError::RemoteApi {
        detail: format!("{operation} returned invalid or drifted JSON payload: {err}"),
        source: Some(Box::new(err)),
    })
}

fn percent_encode(input: &str) -> String {
    let mut encoded = String::with_capacity(input.len());
    for byte in input.bytes() {
        let unreserved = byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'_' | b'.' | b'~');
        if unreserved {
            encoded.push(char::from(byte));
        } else {
            use std::fmt::Write as _;
            let _ = write!(&mut encoded, "%{byte:02X}");
        }
    }
    encoded
}

impl ProjectsPort for HttpProjectsPort {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        let mut url = format!("{}/projects", self.base_url);
        let mut sep = '?';
        if let Some(workspace) = &query.workspace {
            url.push(sep);
            url.push_str("workspace=");
            url.push_str(&percent_encode(workspace));
            sep = '&';
        }
        if let Some(limit) = query.limit {
            use std::fmt::Write as _;
            let _ = write!(&mut url, "{sep}limit={limit}");
        }

        let span = tracing::info_span!(
            "http.client.request",
            otel.kind = "client",
            http.request.method = "GET"
        );
        let _enter = span.enter();
        let mut auth = self.bearer_header();
        let mut req = self
            .agent
            .get(&url)
            .header("Authorization", &auth)
            .header("Accept", "application/json");
        for (name, val) in self.outbound_headers() {
            req = req.header(&name, &val);
        }
        let result = req.call();
        auth.zeroize();

        let response = result.map_err(|err| PortError::Transport {
            source: Box::new(err),
        })?;
        let status = response.status().as_u16();
        // R03 AC8: HTTP 404 on a collection endpoint is an upstream error, NEVER Ok(vec![]).
        if status != 200 {
            return Err(map_error_status("GET /projects", status));
        }

        let envelope: Envelope<Vec<WireProject>> = read_json_body("GET /projects", response)?;
        envelope
            .data
            .into_iter()
            .map(WireProject::into_domain)
            .collect()
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        let url = format!("{}/projects/{}", self.base_url, percent_encode(id));
        let span = tracing::info_span!(
            "http.client.request",
            otel.kind = "client",
            http.request.method = "GET"
        );
        let _enter = span.enter();
        let mut auth = self.bearer_header();
        let mut req = self
            .agent
            .get(&url)
            .header("Authorization", &auth)
            .header("Accept", "application/json");
        for (name, val) in self.outbound_headers() {
            req = req.header(&name, &val);
        }
        let result = req.call();
        auth.zeroize();

        let response = result.map_err(|err| PortError::Transport {
            source: Box::new(err),
        })?;
        let status = response.status().as_u16();
        match status {
            200 => {
                // R03 AC9: malformed 200 payload is Err(RemoteApi), NEVER Ok(None).
                let envelope: Envelope<WireProject> =
                    read_json_body("GET /projects/{id}", response)?;
                Ok(Some(envelope.data.into_domain()?))
            }
            404 => Ok(None),
            other => Err(map_error_status("GET /projects/{id}", other)),
        }
    }

    fn create(&self, input: &CreateProjectInput) -> Result<Project, PortError> {
        let url = format!("{}/projects", self.base_url);
        let payload = CreateProjectPayload {
            name: &input.name,
            workspace: input.workspace.as_deref(),
        };

        let span = tracing::info_span!(
            "http.client.request",
            otel.kind = "client",
            http.request.method = "POST"
        );
        let _enter = span.enter();
        let mut auth = self.bearer_header();
        let mut req = self
            .agent
            .post(&url)
            .header("Authorization", &auth)
            .header("Accept", "application/json");
        for (name, val) in self.outbound_headers() {
            req = req.header(&name, &val);
        }
        let result = req.send_json(&payload);
        auth.zeroize();

        let response = result.map_err(|err| PortError::Transport {
            source: Box::new(err),
        })?;
        let status = response.status().as_u16();
        match status {
            200 | 201 => {
                let envelope: Envelope<WireProject> = read_json_body("POST /projects", response)?;
                envelope.data.into_domain()
            }
            other => Err(map_error_status("POST /projects", other)),
        }
    }

    fn delete(&self, id: &str) -> Result<bool, PortError> {
        let url = format!("{}/projects/{}", self.base_url, percent_encode(id));
        let span = tracing::info_span!(
            "http.client.request",
            otel.kind = "client",
            http.request.method = "DELETE"
        );
        let _enter = span.enter();
        let mut auth = self.bearer_header();
        let mut req = self
            .agent
            .delete(&url)
            .header("Authorization", &auth)
            .header("Accept", "application/json");
        for (name, val) in self.outbound_headers() {
            req = req.header(&name, &val);
        }
        let result = req.call();
        auth.zeroize();

        let response = result.map_err(|err| PortError::Transport {
            source: Box::new(err),
        })?;
        let status = response.status().as_u16();
        match status {
            200 | 202 | 204 => Ok(true),
            404 => Ok(false),
            other => Err(map_error_status("DELETE /projects/{id}", other)),
        }
    }
}
