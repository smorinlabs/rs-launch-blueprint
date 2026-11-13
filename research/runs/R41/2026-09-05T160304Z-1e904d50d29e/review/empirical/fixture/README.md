# R41 acceptance fixture

Three-member workspace (library, CLI, web stand-in) with one registry dependency
already resolved in `Cargo.lock` (`anyhow`) and one declared but unused
(`serde_json`) so a stale-lock case can add a real registry edge. The `crates/web`
member is a leaf (nothing depends on it), so removing it from `[workspace].members`
leaves an orphan `[[package]] name = "r41-web"` entry in `Cargo.lock` that every
`--locked` Cargo command accepts (revision-3 regression cases E1–E3).
