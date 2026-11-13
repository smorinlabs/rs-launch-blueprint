// Variant: per-site `#[expect]` with a reason. Expected under forbid: E0453 as well
// (this is the measured cost of forbid versus deny).
#[expect(unsafe_code, reason = "fixture: demonstrates that forbid also rejects expect")]
pub fn head(x: &[u8]) -> u8 {
    assert!(!x.is_empty());
    // SAFETY: the assert above guarantees index 0 is in bounds.
    unsafe { *x.get_unchecked(0) }
}
