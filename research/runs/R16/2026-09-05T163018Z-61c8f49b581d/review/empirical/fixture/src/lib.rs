//! R16 empirical fixture: one CodeQL marker per placement.
//! Nothing here is ever executed; the functions exist only to be scanned.
#![allow(dead_code, unused_unsafe)]

/// Marker for `rust/access-after-lifetime-ended` (security-extended only).
pub fn dangling_pointer_src() -> i64 {
    fn get_pointer() -> *const i64 {
        let val = 123;
        &val
    } // lifetime of `val` ends here
    let ptr = get_pointer();
    let v;
    unsafe {
        v = *ptr; // BAD: dereferenced after the lifetime of `val` has ended
    }
    v
}

/// Marker for `rust/access-invalid-pointer` (default suite).
pub fn invalid_pointer_src() -> i64 {
    let ptr = Box::into_raw(Box::new(5i64));
    unsafe {
        std::ptr::drop_in_place(ptr); // executes the destructor of `*ptr`
    }
    unsafe { *ptr } // BAD: dereferences `ptr` after drop_in_place
}

/// Marker for `rust/log-injection` (security-extended only); source is argv,
/// which CodeQL classifies under the `local` threat model.
pub fn log_argv_src() {
    let args: Vec<String> = std::env::args().collect();
    let username = args.get(1).cloned().unwrap_or_default();
    log::info!("User login attempt: {}", username);
}

#[cfg(test)]
mod tests {
    /// Same marker as `dangling_pointer_src`, inside `#[cfg(test)]` in `src/`.
    fn dangling_pointer_src_cfgtest() -> i64 {
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
    fn compiles() {
        let _ = dangling_pointer_src_cfgtest as fn() -> i64;
    }
}
