//! Integration-test placement (Cargo `tests/` directory).
#![allow(dead_code, unused_unsafe)]

fn dangling_pointer_tests() -> i64 {
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

#[test]
fn integration_compiles() {
    let _ = dangling_pointer_tests as fn() -> i64;
}
