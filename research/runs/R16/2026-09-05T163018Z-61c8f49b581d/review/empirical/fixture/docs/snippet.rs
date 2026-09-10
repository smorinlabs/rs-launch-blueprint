//! Docs placement: a `.rs` file that is not a Cargo target.
#![allow(dead_code, unused_unsafe)]

fn dangling_pointer_docs() -> i64 {
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
