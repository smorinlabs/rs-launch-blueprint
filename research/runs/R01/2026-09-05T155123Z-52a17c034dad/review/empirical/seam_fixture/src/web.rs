//! F018 — the web layer as a thin adapter: handlers call the same `ErasedProjectsService` the CLI uses
//! and return the library's own contract types. No handler declares a struct that mirrors `Project`.
//!
//! `axum` is the fixture's stand-in framework (three of five raw reports cite its `State` model);
//! the framework selection is R69's. The seam only needs the state to be `Clone + Send + Sync + 'static`,
//! which `ProjectsService<Arc<dyn ProjectsPort>>` is. The port is synchronous here, so handlers call it
//! directly; how a blocking production adapter is bridged into an async handler is R05's decision.

use std::net::SocketAddr;

use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::routing::get;
use axum::{Json, Router};
use serde::Deserialize;

use crate::contract::{Project, ProjectQuery};
use crate::service::ErasedProjectsService;

pub fn router(service: ErasedProjectsService) -> Router {
    Router::new()
        .route("/projects", get(list_projects))
        .route("/project", get(get_project))
        .with_state(service)
}

async fn list_projects(
    State(service): State<ErasedProjectsService>,
    Query(query): Query<ProjectQuery>,
) -> Result<Json<Vec<Project>>, (StatusCode, String)> {
    service
        .search(&query)
        .map(Json)
        .map_err(|e| (StatusCode::SERVICE_UNAVAILABLE, e.to_string()))
}

#[derive(Deserialize)]
struct IdQuery {
    id: String,
}

async fn get_project(
    State(service): State<ErasedProjectsService>,
    Query(IdQuery { id }): Query<IdQuery>,
) -> Result<Json<Option<Project>>, (StatusCode, String)> {
    service
        .find(&id)
        .map(Json)
        .map_err(|e| (StatusCode::SERVICE_UNAVAILABLE, e.to_string()))
}

/// Bind `127.0.0.1:0`, serve `router(service)` on a detached thread with its own runtime, and return
/// the bound address. Tests use this to issue real HTTP requests against a live listener.
pub fn serve_in_background(service: ErasedProjectsService) -> std::io::Result<SocketAddr> {
    let (tx, rx) = std::sync::mpsc::channel::<std::io::Result<SocketAddr>>();
    std::thread::spawn(move || {
        let runtime = match tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
        {
            Ok(rt) => rt,
            Err(e) => {
                let _ = tx.send(Err(e));
                return;
            }
        };
        runtime.block_on(async move {
            let listener = match tokio::net::TcpListener::bind(("127.0.0.1", 0)).await {
                Ok(l) => l,
                Err(e) => {
                    let _ = tx.send(Err(e));
                    return;
                }
            };
            let _ = tx.send(listener.local_addr());
            if let Err(e) = axum::serve(listener, router(service)).await {
                eprintln!("fixture web adapter stopped: {e}");
            }
        });
    });
    rx.recv()
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::BrokenPipe, e.to_string()))?
}
