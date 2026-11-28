//! Local test factories for the `cli` integration tier (`R32` M4).
//!
//! No global setup or autouse fixtures; every test creates its own isolated
//! temporary directory and loopback HTTP stub.

use std::io::{BufRead, BufReader, Read, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::thread::{self, JoinHandle};
use std::time::Duration;

/// Recorded HTTP request captured by [`StubHttpServer`].
#[derive(Debug, Clone)]
pub(crate) struct RecordedRequest {
    pub(crate) method: String,
    pub(crate) path: String,
    pub(crate) authorization: Option<String>,
    pub(crate) body: String,
}

/// Canned HTTP response served by [`StubHttpServer`].
#[derive(Debug, Clone)]
pub(crate) struct StubResponse {
    pub(crate) status: u16,
    pub(crate) body: String,
}

impl StubResponse {
    pub(crate) fn ok_json(body: impl Into<String>) -> Self {
        Self {
            status: 200,
            body: body.into(),
        }
    }

    pub(crate) fn status(status: u16, body: impl Into<String>) -> Self {
        Self {
            status,
            body: body.into(),
        }
    }
}

/// Pure-`std` loopback HTTP/1.1 stub server for built-binary CLI tests.
///
/// Avoids async runtime dependencies in CLI integration tests so both Cargo
/// and Blaze execute the entire suite cleanly.
pub(crate) struct StubHttpServer {
    addr: SocketAddr,
    stop: Arc<AtomicBool>,
    requests: Arc<Mutex<Vec<RecordedRequest>>>,
    handle: Option<JoinHandle<()>>,
}

impl StubHttpServer {
    pub(crate) fn start<F>(handler: F) -> Self
    where
        F: Fn(&RecordedRequest) -> StubResponse + Send + 'static,
    {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind loopback test server");
        listener
            .set_nonblocking(true)
            .expect("set nonblocking on test listener");
        let addr = listener.local_addr().expect("local addr");
        let stop = Arc::new(AtomicBool::new(false));
        let requests = Arc::new(Mutex::new(Vec::new()));

        let stop_bg = Arc::clone(&stop);
        let reqs_bg = Arc::clone(&requests);
        let handle = thread::spawn(move || {
            while !stop_bg.load(Ordering::Relaxed) {
                match listener.accept() {
                    Ok((stream, _)) => {
                        let _ = stream.set_nonblocking(false);
                        let _ = stream.set_read_timeout(Some(Duration::from_secs(5)));
                        let _ = stream.set_write_timeout(Some(Duration::from_secs(5)));
                        if let Some(req) = read_http_request(&stream) {
                            let resp = handler(&req);
                            reqs_bg.lock().expect("lock requests").push(req);
                            write_http_response(stream, &resp);
                        }
                    }
                    Err(err) if err.kind() == std::io::ErrorKind::WouldBlock => {
                        thread::sleep(Duration::from_millis(5));
                    }
                    Err(_) => break,
                }
            }
        });

        Self {
            addr,
            stop,
            requests,
            handle: Some(handle),
        }
    }

    pub(crate) fn base_url(&self) -> String {
        format!("http://{}/v1", self.addr)
    }

    pub(crate) fn requests(&self) -> Vec<RecordedRequest> {
        self.requests.lock().expect("lock requests").clone()
    }
}

impl Drop for StubHttpServer {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::Relaxed);
        let _ = TcpStream::connect(self.addr);
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
    }
}

fn read_http_request(stream: &TcpStream) -> Option<RecordedRequest> {
    let mut reader = BufReader::new(stream);
    let mut request_line = String::new();
    if reader.read_line(&mut request_line).ok()? == 0 {
        return None;
    }
    let mut parts = request_line.split_whitespace();
    let method = parts.next()?.to_owned();
    let path = parts.next()?.to_owned();

    let mut authorization = None;
    let mut content_length = 0usize;
    loop {
        let mut line = String::new();
        if reader.read_line(&mut line).ok()? == 0 {
            break;
        }
        let trimmed = line.trim_end_matches(['\r', '\n']);
        if trimmed.is_empty() {
            break;
        }
        if let Some((name, val)) = trimmed.split_once(':') {
            let lower = name.trim().to_ascii_lowercase();
            let val = val.trim();
            if lower == "authorization" {
                authorization = Some(val.to_owned());
            } else if lower == "content-length" {
                content_length = val.parse().unwrap_or(0);
            }
        }
    }

    let mut body_bytes = vec![0u8; content_length];
    if content_length > 0 {
        let _ = reader.read_exact(&mut body_bytes);
    }
    let body = String::from_utf8_lossy(&body_bytes).into_owned();

    Some(RecordedRequest {
        method,
        path,
        authorization,
        body,
    })
}

fn write_http_response(mut stream: TcpStream, resp: &StubResponse) {
    let reason = match resp.status {
        200 => "OK",
        201 => "Created",
        204 => "No Content",
        401 => "Unauthorized",
        404 => "Not Found",
        409 => "Conflict",
        500 => "Internal Server Error",
        _ => "Status",
    };
    let payload = format!(
        "HTTP/1.1 {} {reason}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        resp.status,
        resp.body.len(),
        resp.body
    );
    let _ = stream.write_all(payload.as_bytes());
    let _ = stream.flush();
}
