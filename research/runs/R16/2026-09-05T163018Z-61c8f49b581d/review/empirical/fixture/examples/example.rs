//! Example placement (Cargo `examples/` directory).
#![allow(dead_code, unused_unsafe)]

fn dangling_pointer_examples() -> i64 {
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

fn main() {
    let _ = dangling_pointer_examples as fn() -> i64;
}
