// Variant: per-site `#[allow]`. Expected under forbid: E0453 (allow incompatible with previous forbid).
#[allow(unsafe_code)]
pub fn head(x: &[u8]) -> u8 {
    assert!(!x.is_empty());
    // SAFETY: the assert above guarantees index 0 is in bounds.
    unsafe { *x.get_unchecked(0) }
}
