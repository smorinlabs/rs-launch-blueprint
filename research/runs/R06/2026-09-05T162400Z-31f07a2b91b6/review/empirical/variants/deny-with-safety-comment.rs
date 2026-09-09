// Runner-up contrast (root switched to `unsafe_code = "deny"`): one unsafe op per
// block, safety comment present on the line above it. Expected: clippy clean
// under -D warnings. (This header must not contain the safety-comment token
// itself: `unnecessary_safety_comment` matches it textually on the preceding
// comment lines of a safe item.)
#[expect(unsafe_code, reason = "fixture: single justified read; see the comment above the block")]
pub fn head(x: &[u8]) -> u8 {
    assert!(!x.is_empty());
    // SAFETY: the assert above guarantees index 0 is in bounds.
    unsafe { *x.get_unchecked(0) }
}
