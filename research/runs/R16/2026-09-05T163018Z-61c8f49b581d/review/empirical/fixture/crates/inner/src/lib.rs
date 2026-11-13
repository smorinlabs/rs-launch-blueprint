//! Workspace-member placement (crates/inner/src): shipped code in a nested crate.
#![allow(dead_code, unused_unsafe)]

pub fn dangling_pointer_inner_src() -> i64 {
    fn get_pointer() -> *const i64 {
        let val = 123;
        &val
    }
    let ptr = get_pointer();
    let v;
    unsafe {
        v = *ptr;
    }
    v
}
