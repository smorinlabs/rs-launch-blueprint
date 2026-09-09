// Variant: a plain `unsafe` block. Expected under forbid: error `usage of an `unsafe` block`.
pub fn head(x: &[u8]) -> u8 {
    unsafe { *x.get_unchecked(0) }
}
