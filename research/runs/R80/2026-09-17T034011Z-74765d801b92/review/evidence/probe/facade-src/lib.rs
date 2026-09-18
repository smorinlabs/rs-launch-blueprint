// R80 probe workspace — the facade (root) package. It exists so checks A and B
// can compare `env!("CARGO_PKG_VERSION")` as seen by the distributed artifact
// against the same macro as seen by an inner workspace member.
pub const FACADE_PKG_VERSION: &str = env!("CARGO_PKG_VERSION");
