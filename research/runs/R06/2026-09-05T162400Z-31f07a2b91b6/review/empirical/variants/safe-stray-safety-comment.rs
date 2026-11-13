// Variant under forbid: entirely safe code carrying a safety comment it does not
// need. Expected: `cargo check` passes (no unsafe), but `cargo clippy -D warnings`
// fails with `unnecessary safety comment`. This shows the third shipped clippy
// lint is live, not dormant, under forbid: it rejects the safety-comment
// vocabulary on safe code, which under forbid is all code.
pub fn head(x: &[u8]) -> Option<u8> {
    // SAFETY: nothing here is unsafe; this comment is the thing under test.
    x.first().copied()
}
