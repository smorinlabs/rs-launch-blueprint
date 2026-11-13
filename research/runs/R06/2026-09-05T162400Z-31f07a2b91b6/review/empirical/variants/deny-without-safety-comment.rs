// Runner-up contrast (root switched to `unsafe_code = "deny"`): same code, the
// safety comment removed. Expected: clippy error `unsafe block missing a safety comment`.
#[expect(unsafe_code, reason = "fixture: single justified read; safety comment deliberately omitted")]
pub fn head(x: &[u8]) -> u8 {
    assert!(!x.is_empty());
    unsafe { *x.get_unchecked(0) }
}
