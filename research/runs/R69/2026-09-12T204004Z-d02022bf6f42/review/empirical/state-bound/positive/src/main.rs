// R01's published seam shape, transcribed from
// research/topics/01-ports-and-adapters-seam/DECISION.md, `## Parameters`.
// TYPES ONLY: no methods, no behavior, no I/O, no framework. This file exists
// to assert a trait bound, not to implement or exercise the seam.
pub trait ProjectsPort: Send + Sync {}
impl<T: ProjectsPort + ?Sized> ProjectsPort for std::sync::Arc<T> {}

// The use case is generic over the port and DELIBERATELY does not derive Clone.
pub struct ProjectsService<P: ProjectsPort> { _port: P }
pub type ErasedProjectsService = ProjectsService<std::sync::Arc<dyn ProjectsPort>>;

// The typed settings struct R77 owns; also deliberately not Clone.
pub struct WebConfig { _port: u16 }

// axum 0.8.9's state bound, transcribed verbatim from the published artifact
// `axum-0.8.9/src/routing/mod.rs:138-141`:
//     impl<S> Router<S> where S: Clone + Send + Sync + 'static
pub fn assert_axum_state_bound<S: Clone + Send + Sync + 'static>() {}

fn main() {
    // Claim 1: the erased service, Arc-held, satisfies axum's state bound
    // WITHOUT ProjectsService deriving Clone.
    assert_axum_state_bound::<std::sync::Arc<ErasedProjectsService>>();

    // Claim 2: the recommended AppState (its own Clone derive over Arc fields)
    // satisfies the same bound with neither inner type deriving Clone.
    #[derive(Clone)]
    struct AppState {
        _config: std::sync::Arc<WebConfig>,
        _projects: std::sync::Arc<ErasedProjectsService>,
    }
    assert_axum_state_bound::<AppState>();
}
