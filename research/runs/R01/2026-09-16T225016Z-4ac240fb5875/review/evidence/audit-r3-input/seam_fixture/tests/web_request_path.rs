//! F018 — a real HTTP request against a bound listener, decoded into the library's own contract type.
//! The client here is a raw `std::net::TcpStream` GET so the test adds no HTTP-client crate.

use std::io::{Read, Write};
use std::net::TcpStream;
use std::sync::Arc;

use seam_fixture::testing::sample_rows;
use seam_fixture::web::serve_in_background;
use seam_fixture::{InMemoryProjectsPort, Project, build_projects_service};

fn http_get(authority: &str, path_and_query: &str) -> (String, Vec<u8>) {
    let mut stream = TcpStream::connect(authority).expect("connect to fixture listener");
    write!(
        stream,
        "GET {path_and_query} HTTP/1.1\r\nHost: {authority}\r\nAccept: application/json\r\nConnection: close\r\n\r\n"
    )
    .expect("write request");
    let mut raw = Vec::new();
    stream.read_to_end(&mut raw).expect("read response");
    let split = raw
        .windows(4)
        .position(|w| w == b"\r\n\r\n")
        .expect("header/body separator");
    let head = String::from_utf8_lossy(&raw[..split]).to_string();
    (head, raw[split + 4..].to_vec())
}

#[test]
fn web_adapter_serves_the_shared_contract_over_a_live_listener() {
    let service = build_projects_service(Arc::new(InMemoryProjectsPort::seeded(sample_rows())));
    let addr = serve_in_background(service).expect("bind 127.0.0.1:0");
    let authority = addr.to_string();

    let (head, body) = http_get(&authority, "/projects?q=alpha");
    let status_line = head.lines().next().unwrap_or_default().to_string();
    assert!(
        status_line.starts_with("HTTP/1.1 200"),
        "status line was {status_line:?}"
    );
    assert!(
        head.to_ascii_lowercase()
            .contains("content-type: application/json"),
        "web adapter emits JSON; headers were:\n{head}"
    );
    let alpha_body = String::from_utf8_lossy(&body).to_string();
    let decoded: Vec<Project> =
        serde_json::from_slice(&body).expect("body is the library's Vec<Project>");
    assert_eq!(
        decoded,
        vec![
            Project {
                id: "1".into(),
                name: "alpha".into()
            },
            Project {
                id: "3".into(),
                name: "alphabet".into()
            },
        ],
        "the web layer returns the same value the service returns to the CLI, sorted by the service"
    );

    let (head, body) = http_get(&authority, "/project?id=2");
    assert!(head.starts_with("HTTP/1.1 200"), "head was:\n{head}");
    let decoded: Option<Project> = serde_json::from_slice(&body).expect("Option<Project>");
    assert_eq!(
        decoded,
        Some(Project {
            id: "2".into(),
            name: "beta".into()
        })
    );

    let (head, body) = http_get(&authority, "/project?id=404");
    assert!(head.starts_with("HTTP/1.1 200"), "head was:\n{head}");
    assert_eq!(
        body, b"null",
        "absence is serialized as the library's Option, not a second web type"
    );

    println!("fixture listener {authority}: GET /projects?q=alpha -> {alpha_body}");
}
