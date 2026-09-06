//! Curated public surface: this file is the only sanctioned import path.
//!
//! A deep import of an internal module does not compile:
//! ```compile_fail,E0603
//! use surface_demo::internal::Engine;
//! ```
//!
//! A crate-private constant is unreachable by path:
//! ```compile_fail,E0603
//! let _ = surface_demo::internal::SECRET;
//! ```
//!
//! The curated re-export does compile:
//! ```
//! use surface_demo::Widget;
//! assert_eq!(Widget::new(7).id(), 7);
//! ```
#![deny(unreachable_pub)]
#![deny(private_interfaces, private_bounds)]
#![deny(missing_docs)]

mod internal;

pub use internal::Widget;
