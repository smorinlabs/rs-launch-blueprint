//! Bench placement (Cargo `benches/` directory, harness = false).
#![allow(dead_code, unused_unsafe)]

fn dangling_pointer_benches() -> i64 {
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
    let _ = dangling_pointer_benches as fn() -> i64;
}
