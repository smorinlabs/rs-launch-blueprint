# R41 acceptance fixture

Three-member workspace (library, CLI, web stand-in) with one registry dependency
already resolved in `Cargo.lock` (`anyhow`) and one declared but unused
(`serde_json`) so a stale-lock case can add a real registry edge.
