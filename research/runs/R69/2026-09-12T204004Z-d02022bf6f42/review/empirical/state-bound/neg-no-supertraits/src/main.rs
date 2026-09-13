// Negative twin B: identical to the positive case EXCEPT that R01's
// `Send + Sync` supertraits are removed from the port. Must fail, showing those
// supertraits are what make the erased service shareable as axum state.
pub trait ProjectsPort {}                                   // R01 writes: `: Send + Sync`
impl<T: ProjectsPort + ?Sized> ProjectsPort for std::sync::Arc<T> {}

pub struct ProjectsService<P: ProjectsPort> { _port: P }
pub type ErasedProjectsService = ProjectsService<std::sync::Arc<dyn ProjectsPort>>;

// axum 0.8.9's state bound, transcribed from `axum-0.8.9/src/routing/mod.rs:138-141`.
pub fn assert_axum_state_bound<S: Clone + Send + Sync + 'static>() {}

fn main() {
    assert_axum_state_bound::<std::sync::Arc<ErasedProjectsService>>();
}
