//! Public facade over an internal workspace member.
#![deny(missing_docs)]

/// Returns the internal answer through the facade.
pub fn answer() -> u32 {
    rs_publish_demo_internal::answer()
}
