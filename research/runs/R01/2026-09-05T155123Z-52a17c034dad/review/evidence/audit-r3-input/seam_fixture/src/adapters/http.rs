//! The "real" driven-I/O adapter: fetches the shared contract over HTTP from a base address.
//!
//! Fixture-only transport: a minimal HTTP/1.1 GET over `std::net::TcpStream` with `Connection: close`,
//! so the fixture selects no HTTP-client crate (that selection belongs to other items) and no async
//! runtime for the port (R05). What matters for R01 is the seam: this type is injected through the
//! same `ProjectsPort` trait as the fake, and the same contract suite runs against both.

use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::Duration;

use serde::de::DeserializeOwned;

use crate::contract::{Project, ProjectQuery};
use crate::ports::{PortError, ProjectsPort};

#[derive(Debug, Clone)]
pub struct HttpProjectsPort {
    /// `host:port` of the upstream serving `/projects?q=` and `/project?id=`.
    authority: String,
}

impl HttpProjectsPort {
    pub fn new(authority: impl Into<String>) -> Self {
        Self {
            authority: authority.into(),
        }
    }

    fn fetch_json<T: DeserializeOwned>(&self, path_and_query: &str) -> Result<T, PortError> {
        let unavailable =
            |e: std::io::Error| PortError::Unavailable(format!("{}: {e}", self.authority));
        let mut stream = TcpStream::connect(&self.authority).map_err(unavailable)?;
        stream
            .set_read_timeout(Some(Duration::from_secs(10)))
            .map_err(unavailable)?;
        stream
            .set_write_timeout(Some(Duration::from_secs(10)))
            .map_err(unavailable)?;
        write!(
            stream,
            "GET {path_and_query} HTTP/1.1\r\nHost: {}\r\nAccept: application/json\r\nConnection: close\r\n\r\n",
            self.authority
        )
        .map_err(unavailable)?;
        let mut raw = Vec::new();
        stream.read_to_end(&mut raw).map_err(unavailable)?;

        let split = raw
            .windows(4)
            .position(|w| w == b"\r\n\r\n")
            .ok_or_else(|| PortError::Decode("no header/body separator in response".into()))?;
        let head = String::from_utf8_lossy(&raw[..split]);
        let status_line = head.lines().next().unwrap_or_default();
        if !status_line.starts_with("HTTP/1.1 200") && !status_line.starts_with("HTTP/1.0 200") {
            return Err(PortError::Unavailable(format!(
                "upstream answered {status_line:?}"
            )));
        }
        serde_json::from_slice(&raw[split + 4..]).map_err(|e| PortError::Decode(e.to_string()))
    }
}

/// Percent-encode everything outside RFC 3986 unreserved characters (fixture-sized encoder).
fn encode(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    for byte in value.bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(byte as char)
            }
            _ => out.push_str(&format!("%{byte:02X}")),
        }
    }
    out
}

impl ProjectsPort for HttpProjectsPort {
    fn list(&self, query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        let path = match &query.q {
            Some(q) => format!("/projects?q={}", encode(q)),
            None => "/projects".to_string(),
        };
        self.fetch_json(&path)
    }

    fn get(&self, id: &str) -> Result<Option<Project>, PortError> {
        self.fetch_json(&format!("/project?id={}", encode(id)))
    }
}
