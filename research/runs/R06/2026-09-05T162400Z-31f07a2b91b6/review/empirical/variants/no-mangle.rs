// Variant: an unsafe attribute (edition-2024 spelling), no unsafe block.
// Expected under forbid: error `usage of the unsafe `#[no_mangle]` attribute`.
#[unsafe(no_mangle)]
pub extern "C" fn demo_symbol() -> u32 {
    7
}
