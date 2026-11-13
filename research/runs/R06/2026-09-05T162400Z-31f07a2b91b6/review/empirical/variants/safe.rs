//! Resting state: safe code only, calling a registry dependency (`memchr`) whose
//! own source uses `unsafe` heavily. Must pass check, test and clippy.
pub fn first_comma(haystack: &[u8]) -> Option<usize> {
    memchr::memchr(b',', haystack)
}

pub fn head(x: &[u8]) -> Option<u8> {
    x.first().copied()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_comma() {
        assert_eq!(first_comma(b"a,b"), Some(1));
        assert_eq!(head(b"z"), Some(b'z'));
    }
}
