use seam_fixture::{Project, ProjectQuery, PortError, ProjectsPort};

struct Incomplete;

impl ProjectsPort for Incomplete {
    fn list(&self, _query: &ProjectQuery) -> Result<Vec<Project>, PortError> {
        Ok(vec![])
    }
}

fn main() {
    let _: std::sync::Arc<dyn ProjectsPort> = std::sync::Arc::new(Incomplete);
}
