//! Implementation module. Nothing here is a public path; `lib.rs` re-exports
//! the sanctioned items.

pub(crate) const SECRET: u32 = 42;

/// Crate-internal helper type; never exported.
pub(crate) struct Engine;

/// A widget identified by a number.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Widget {
    id: u32,
}

impl Widget {
    /// Creates a widget with the given id.
    pub fn new(id: u32) -> Self {
        let _ = Engine;
        let _ = SECRET;
        Self { id }
    }

    /// Returns the id.
    pub fn id(&self) -> u32 {
        self.id
    }
}
