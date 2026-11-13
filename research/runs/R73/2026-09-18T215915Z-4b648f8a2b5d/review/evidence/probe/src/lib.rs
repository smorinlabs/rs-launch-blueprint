#![forbid(unsafe_code)]
//! R73 synthesis probe — a RE-DERIVED reimplementation of `idempotency-replay/v1`.
//!
//! This is NOT the Opus raw report's probe source. That workspace was created
//! under `$TMPDIR` and deleted after the run (raw/opus.md:1081, :1261-1262), so
//! no source survived to re-run. Everything here was re-derived from the raw
//! report's prose clauses by the synthesizer. Behavioural agreement with the
//! raw report's 22 checks is therefore evidence that the DESIGN is executable
//! and behaves as described; it is not a byte-level reproduction of that run.
//!
//! Layout mirrors the template the decision recommends:
//!   * `port`    stands in for `crates/core/src/idempotency.rs`
//!   * `adapter` stands in for the root package's composition-root adapter
//!   * `layer`   stands in for `crates/web/src/idempotency.rs`
//!
//! Deliberate probe-only departures, each stated so no reader mistakes the
//! probe for the recommendation:
//!   * `PortError` is hand-implemented rather than `thiserror`-derived. R67
//!     places `thiserror` in the library crate, so the template would derive
//!     it; the probe avoids the dependency so the measured crate deltas stay
//!     honest.
//!   * `problem()` emits a bare JSON object, not R70's `application/problem+json`
//!     envelope. R70 owns the body; the probe only needs the status.

pub mod adapter;
pub mod layer;
pub mod port;
